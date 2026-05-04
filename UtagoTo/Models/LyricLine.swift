import Foundation
import SwiftData

@Model
final class LyricLine {
    var id: UUID
    var lineIndex: Int
    var originalText: String
    var romajiText: String?
    var translationText: String?
    var timestampStart: Double?
    var timestampEnd: Double?
    var song: Song?

    init(
        id: UUID = UUID(),
        lineIndex: Int,
        originalText: String,
        romajiText: String? = nil,
        translationText: String? = nil,
        timestampStart: Double? = nil,
        timestampEnd: Double? = nil,
        song: Song? = nil
    ) {
        self.id = id
        self.lineIndex = lineIndex
        self.originalText = originalText
        self.romajiText = romajiText
        self.translationText = translationText
        self.timestampStart = timestampStart
        self.timestampEnd = timestampEnd
        self.song = song
    }
}
