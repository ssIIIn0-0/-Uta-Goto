import Foundation
import SwiftData
import Combine

@Observable
final class PlayerViewModel {
    var currentSong: Song?
    var tokenizedLines: [[TokenWord]] = []
    var selectedWord: TokenWord?
    var showWordDetail: Bool = false
    var showRomaji: Bool = false
    var showTranslation: Bool = true

    let audioService = AudioSyncService()
    private let parser = LyricParserService.shared
    private let translator = TranslationService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {}

    func loadSong(_ song: Song) {
        currentSong = song
        tokenizedLines = song.sortedLyricLines.map { parser.tokenize(line: $0.originalText) }
        audioService.load(song: song)

        song.totalPlayCount += 1
        song.lastPlayedAt = Date()

        let lines = song.sortedLyricLines
        let needsTranslation = lines.allSatisfy { ($0.translationText ?? "").isEmpty }
        if needsTranslation && !lines.isEmpty {
            fetchTranslations(for: song)
        }
    }

    private func fetchTranslations(for song: Song) {
        let lines = song.sortedLyricLines
        let texts = lines.map { $0.originalText }
        Task {
            let translations = await translator.translate(lines: texts)
            await MainActor.run {
                for (index, line) in lines.enumerated() {
                    if index < translations.count && !translations[index].isEmpty {
                        line.translationText = translations[index]
                    }
                }
            }
        }
    }

    func selectWord(_ token: TokenWord) {
        selectedWord = token
        showWordDetail = true
    }

    func retokenize() {
        guard let song = currentSong else { return }
        tokenizedLines = song.sortedLyricLines.map { parser.tokenize(line: $0.originalText) }
    }

    var hasTimestamps: Bool {
        guard let song = currentSong else { return false }
        return song.sortedLyricLines.contains { $0.timestampStart != nil }
    }

    var sortedLines: [LyricLine] {
        currentSong?.sortedLyricLines ?? []
    }
}
