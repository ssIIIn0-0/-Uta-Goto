import Foundation
import SwiftData
import SwiftUI

@Observable
final class LibraryViewModel {
    var songs: [Song] = []
    var errorMessage: String?

    private var modelContext: ModelContext?

    func setup(context: ModelContext) {
        self.modelContext = context
        fetchSongs()
    }

    func fetchSongs() {
        guard let context = modelContext else { return }
        do {
            let descriptor = FetchDescriptor<Song>(sortBy: [SortDescriptor(\.addedAt, order: .reverse)])
            songs = try context.fetch(descriptor)
        } catch {
            errorMessage = "노래 목록을 불러올 수 없습니다."
        }
    }

    func addSong(title: String, artist: String, lrcContent: String, translations: [String], audioFileName: String? = nil, audioURLString: String? = nil, appleMusicID: String? = nil, thumbnailData: Data? = nil) {
        guard let context = modelContext else { return }

        let song = Song(title: title, artist: artist, appleMusicID: appleMusicID, audioFileName: audioFileName, audioURLString: audioURLString, thumbnailData: thumbnailData)

        let parser = LyricParserService.shared
        let parsed = parser.parseLRC(content: lrcContent)

        if parsed.isEmpty {
            let lines = lrcContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
            for (index, lineText) in lines.enumerated() {
                let cleaned = lineText.trimmingCharacters(in: .whitespaces)
                guard !cleaned.isEmpty else { continue }
                let translation = index < translations.count ? translations[index] : nil
                let lyricLine = LyricLine(
                    lineIndex: index,
                    originalText: cleaned,
                    translationText: translation,
                    song: song
                )
                song.lyricLines.append(lyricLine)
            }
        } else {
            for (index, item) in parsed.enumerated() {
                let translation = index < translations.count ? translations[index] : nil
                let endTime: Double? = index + 1 < parsed.count ? parsed[index + 1].timestamp : nil
                let lyricLine = LyricLine(
                    lineIndex: index,
                    originalText: item.text,
                    translationText: translation,
                    timestampStart: item.timestamp,
                    timestampEnd: endTime,
                    song: song
                )
                song.lyricLines.append(lyricLine)
            }
        }

        context.insert(song)
        save()
        fetchSongs()
    }

    func deleteSong(_ song: Song) {
        guard let context = modelContext else { return }
        context.delete(song)
        save()
        fetchSongs()
    }

    func deleteSongs(at offsets: IndexSet) {
        for index in offsets {
            guard index < songs.count else { continue }
            deleteSong(songs[index])
        }
    }

    private func save() {
        guard let context = modelContext else { return }
        do {
            try context.save()
        } catch {
            errorMessage = "저장에 실패했습니다."
        }
    }

    func jlptDistribution(for song: Song) -> [JLPTLevel: Int] {
        let parser = LyricParserService.shared
        var counts: [JLPTLevel: Int] = [:]

        for line in song.sortedLyricLines {
            let tokens = parser.tokenize(line: line.originalText)
            for token in tokens where token.isJapanese {
                counts[token.jlptLevel, default: 0] += 1
            }
        }

        return counts
    }
}
