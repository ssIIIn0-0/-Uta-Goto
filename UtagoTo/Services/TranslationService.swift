import Foundation

final class TranslationService {
    static let shared = TranslationService()

    func translate(lines: [String]) async -> [String] {
        await withTaskGroup(of: (Int, String).self) { group in
            for (index, line) in lines.enumerated() {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    group.addTask { (index, "") }
                    continue
                }
                group.addTask {
                    let result = await self.translateLine(trimmed)
                    return (index, result)
                }
            }

            var results = Array(repeating: "", count: lines.count)
            for await (index, translation) in group {
                results[index] = translation
            }
            return results
        }
    }

    private func translateLine(_ text: String) async -> String {
        var components = URLComponents(string: "https://api.mymemory.translated.net/get")!
        components.queryItems = [
            URLQueryItem(name: "q", value: text),
            URLQueryItem(name: "langpair", value: "ja|ko")
        ]
        guard let url = components.url else { return "" }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let responseData = json["responseData"] as? [String: Any],
                  let translated = responseData["translatedText"] as? String else {
                return ""
            }
            if translated.contains("%") { return "" }
            return translated
        } catch {
            return ""
        }
    }
}
