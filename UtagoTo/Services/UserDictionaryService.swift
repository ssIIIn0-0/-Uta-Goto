import Foundation

final class UserDictionaryService {
    static let shared = UserDictionaryService()

    private var entries: [String: DictionaryEntry] = [:]
    private let fileURL: URL

    private struct StoredEntry: Codable {
        let word: String
        let reading: String
        let meaning: String
        let partOfSpeech: String
        let jlptLevel: String
    }

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = docs.appendingPathComponent("user_dictionary.json")
        load()
    }

    func entry(for word: String) -> DictionaryEntry? {
        entries[word]
    }

    func addEntry(_ entry: DictionaryEntry) {
        entries[entry.word] = entry
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let stored = try? JSONDecoder().decode([StoredEntry].self, from: data) else {
            return
        }
        for item in stored {
            entries[item.word] = DictionaryEntry(
                word: item.word,
                reading: item.reading,
                meaning: item.meaning,
                partOfSpeech: item.partOfSpeech,
                jlptLevel: levelFromString(item.jlptLevel)
            )
        }
    }

    private func save() {
        let stored = entries.values.map {
            StoredEntry(
                word: $0.word,
                reading: $0.reading,
                meaning: $0.meaning,
                partOfSpeech: $0.partOfSpeech,
                jlptLevel: stringFromLevel($0.jlptLevel)
            )
        }
        if let data = try? JSONEncoder().encode(stored) {
            try? data.write(to: fileURL)
        }
    }

    private func levelFromString(_ str: String) -> JLPTLevel {
        switch str {
        case "N5": return .n5
        case "N4": return .n4
        case "N3": return .n3
        case "N2": return .n2
        case "N1": return .n1
        default: return .unknown
        }
    }

    private func stringFromLevel(_ level: JLPTLevel) -> String {
        switch level {
        case .n5: return "N5"
        case .n4: return "N4"
        case .n3: return "N3"
        case .n2: return "N2"
        case .n1: return "N1"
        case .unknown: return ""
        }
    }
}
