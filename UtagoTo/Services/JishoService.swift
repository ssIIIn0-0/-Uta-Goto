import Foundation

final class JishoService {
    static let shared = JishoService()

    private var cache: [String: DictionaryEntry] = [:]

    func lookup(word: String) async -> DictionaryEntry? {
        if let cached = cache[word] { return cached }

        guard let encoded = word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://jisho.org/api/v1/search/words?keyword=\(encoded)") else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["data"] as? [[String: Any]],
                  let first = results.first else { return nil }

            let japanese = (first["japanese"] as? [[String: Any]])?.first
            let reading = japanese?["reading"] as? String ?? ""

            let senses = first["senses"] as? [[String: Any]]
            let firstSense = senses?.first
            let definitions = firstSense?["english_definitions"] as? [String] ?? []
            let meaning = definitions.prefix(3).joined(separator: ", ")

            let partsOfSpeech = firstSense?["parts_of_speech"] as? [String] ?? []
            let pos = mapPartOfSpeech(partsOfSpeech.first ?? "")

            let jlptTags = first["jlpt"] as? [String] ?? []
            let level = mapJLPTLevel(jlptTags)

            let entry = DictionaryEntry(
                word: word,
                reading: reading,
                meaning: meaning,
                partOfSpeech: pos,
                jlptLevel: level
            )
            cache[word] = entry
            return entry
        } catch {
            return nil
        }
    }

    private func mapPartOfSpeech(_ pos: String) -> String {
        if pos.contains("Verb") { return "동사" }
        if pos.contains("Noun") { return "명사" }
        if pos.contains("Adjective") { return "형용사" }
        if pos.contains("Adverb") { return "부사" }
        if pos.contains("Particle") { return "조사" }
        if pos.contains("Conjunction") { return "접속사" }
        if pos.contains("Expression") { return "표현" }
        return pos
    }

    private func mapJLPTLevel(_ tags: [String]) -> JLPTLevel {
        if tags.contains("jlpt-n1") { return .n1 }
        if tags.contains("jlpt-n2") { return .n2 }
        if tags.contains("jlpt-n3") { return .n3 }
        if tags.contains("jlpt-n4") { return .n4 }
        if tags.contains("jlpt-n5") { return .n5 }
        return .unknown
    }
}
