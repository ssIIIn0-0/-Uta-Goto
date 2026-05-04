import Foundation
import SwiftData

@Model
final class VocabEntry {
    var id: UUID
    var word: String
    var reading: String
    var meaning: String
    var partOfSpeech: String
    var jlptLevelRaw: String
    var addedAt: Date
    var lastReviewedAt: Date?
    var reviewCount: Int
    var isFavorite: Bool

    @Relationship(deleteRule: .cascade, inverse: \WordAppearance.vocabEntry)
    var appearances: [WordAppearance]

    var jlptLevel: JLPTLevel {
        get { JLPTLevel(rawValue: jlptLevelRaw) ?? .unknown }
        set { jlptLevelRaw = newValue.rawValue }
    }

    var songContextSummary: String {
        let titles = Set(appearances.compactMap { $0.song?.title })
        if titles.isEmpty { return "" }
        let listed = titles.prefix(2).map { "「\($0)」" }.joined()
        let extra = titles.count > 2 ? " 외 \(titles.count - 2)곡" : ""
        return "\(listed)\(extra)에서 등장"
    }

    init(
        id: UUID = UUID(),
        word: String,
        reading: String,
        meaning: String,
        partOfSpeech: String,
        jlptLevel: JLPTLevel,
        addedAt: Date = Date(),
        lastReviewedAt: Date? = nil,
        reviewCount: Int = 0,
        isFavorite: Bool = false,
        appearances: [WordAppearance] = []
    ) {
        self.id = id
        self.word = word
        self.reading = reading
        self.meaning = meaning
        self.partOfSpeech = partOfSpeech
        self.jlptLevelRaw = jlptLevel.rawValue
        self.addedAt = addedAt
        self.lastReviewedAt = lastReviewedAt
        self.reviewCount = reviewCount
        self.isFavorite = isFavorite
        self.appearances = appearances
    }
}
