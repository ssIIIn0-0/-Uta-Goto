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
    private var cancellables = Set<AnyCancellable>()

    init() {}

    func loadSong(_ song: Song) {
        currentSong = song
        tokenizedLines = song.sortedLyricLines.map { parser.tokenize(line: $0.originalText) }
        audioService.load(song: song)

        song.totalPlayCount += 1
        song.lastPlayedAt = Date()
    }

    func selectWord(_ token: TokenWord) {
        selectedWord = token
        showWordDetail = true
    }

    var hasTimestamps: Bool {
        guard let song = currentSong else { return false }
        return song.sortedLyricLines.contains { $0.timestampStart != nil }
    }

    var sortedLines: [LyricLine] {
        currentSong?.sortedLyricLines ?? []
    }
}
