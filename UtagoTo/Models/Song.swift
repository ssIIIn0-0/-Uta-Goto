import Foundation
import SwiftData

@Model
final class Song {
    var id: UUID
    var title: String
    var artist: String
    var appleMusicID: String?
    var audioFileName: String?
    var audioURLString: String?
    var thumbnailData: Data?
    var addedAt: Date
    var lastPlayedAt: Date?
    var totalPlayCount: Int

    @Relationship(deleteRule: .cascade, inverse: \LyricLine.song)
    var lyricLines: [LyricLine]

    @Relationship(deleteRule: .nullify, inverse: \WordAppearance.song)
    var wordAppearances: [WordAppearance]

    var audioURL: URL? {
        get {
            guard let urlString = audioURLString else { return nil }
            return URL(string: urlString)
        }
        set {
            audioURLString = newValue?.absoluteString
        }
    }

    var sortedLyricLines: [LyricLine] {
        lyricLines.sorted { $0.lineIndex < $1.lineIndex }
    }

    init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        appleMusicID: String? = nil,
        audioFileName: String? = nil,
        audioURLString: String? = nil,
        thumbnailData: Data? = nil,
        addedAt: Date = Date(),
        lastPlayedAt: Date? = nil,
        totalPlayCount: Int = 0,
        lyricLines: [LyricLine] = [],
        wordAppearances: [WordAppearance] = []
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.appleMusicID = appleMusicID
        self.audioFileName = audioFileName
        self.audioURLString = audioURLString
        self.thumbnailData = thumbnailData
        self.addedAt = addedAt
        self.lastPlayedAt = lastPlayedAt
        self.totalPlayCount = totalPlayCount
        self.lyricLines = lyricLines
        self.wordAppearances = wordAppearances
    }
}
