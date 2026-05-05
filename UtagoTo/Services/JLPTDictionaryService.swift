import Foundation

struct DictionaryEntry {
    let word: String
    let reading: String
    let meaning: String
    let partOfSpeech: String
    let jlptLevel: JLPTLevel
}

final class JLPTDictionaryService {
    static let shared = JLPTDictionaryService()

    private var wordToLevel: [String: JLPTLevel] = [:]
    private var readingToLevel: [String: JLPTLevel] = [:]
    private var wordToEntry: [String: DictionaryEntry] = [:]
    private var readingToEntry: [String: DictionaryEntry] = [:]

    private init() {
        loadAllLevels()
    }

    private struct RawEntry: Decodable {
        let word: String
        let reading: String
        let meaning: String
        let pos: String
    }

    private func loadAllLevels() {
        let levels: [(String, JLPTLevel)] = [
            ("jlpt_n5", .n5),
            ("jlpt_n4", .n4),
            ("jlpt_n3", .n3),
            ("jlpt_n2", .n2),
            ("jlpt_n1", .n1)
        ]

        for (fileName, jlptLevel) in levels {
            guard let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let entries = try? JSONDecoder().decode([RawEntry].self, from: data) else {
                continue
            }

            for raw in entries {
                let entry = DictionaryEntry(
                    word: raw.word,
                    reading: raw.reading,
                    meaning: raw.meaning,
                    partOfSpeech: raw.pos,
                    jlptLevel: jlptLevel
                )

                if wordToLevel[raw.word] == nil {
                    wordToLevel[raw.word] = jlptLevel
                    wordToEntry[raw.word] = entry
                }
                if readingToLevel[raw.reading] == nil {
                    readingToLevel[raw.reading] = jlptLevel
                    readingToEntry[raw.reading] = entry
                }
            }
        }
    }

    func level(for word: String) -> JLPTLevel {
        wordToLevel[word] ?? readingToLevel[word] ?? .unknown
    }

    func level(forReading reading: String) -> JLPTLevel {
        readingToLevel[reading] ?? wordToLevel[reading] ?? .unknown
    }

    func entry(for word: String) -> DictionaryEntry? {
        if let userEntry = UserDictionaryService.shared.entry(for: word) {
            return userEntry
        }
        return wordToEntry[word] ?? readingToEntry[word]
    }
}
