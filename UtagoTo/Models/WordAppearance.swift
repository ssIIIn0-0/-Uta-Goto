import Foundation
import SwiftData

@Model
final class WordAppearance {
    var id: UUID
    var vocabEntry: VocabEntry?
    var song: Song?
    var lyricLineText: String
    var lyricLineIndex: Int
    var encounteredAt: Date

    init(
        id: UUID = UUID(),
        vocabEntry: VocabEntry? = nil,
        song: Song? = nil,
        lyricLineText: String,
        lyricLineIndex: Int,
        encounteredAt: Date = Date()
    ) {
        self.id = id
        self.vocabEntry = vocabEntry
        self.song = song
        self.lyricLineText = lyricLineText
        self.lyricLineIndex = lyricLineIndex
        self.encounteredAt = encounteredAt
    }
}
