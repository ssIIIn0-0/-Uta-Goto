import Foundation

struct LyricTranslation: Codable {
    let original: String
    let literal: String
    let natural: String
}

final class TranslationService {
    static let shared = TranslationService()

    #if targetEnvironment(simulator)
    private let baseURL = "http://localhost:3000"
    #else
    private let baseURL = "http://192.168.0.43:3000"
    #endif

    func translate(lines: [String]) async -> [String] {
        let result = await translateFull(lines: lines)
        return result.map { $0.natural }
    }

    func translateFull(lines: [String]) async -> [LyricTranslation] {
        let url = URL(string: "\(baseURL)/translate/lyrics")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["lyrics": lines]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        print("[TranslationService] POST \(url)")
        print("[TranslationService] lines count: \(lines.count)")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            print("[TranslationService] HTTP \(httpResponse?.statusCode ?? -1)")

            guard let code = httpResponse?.statusCode, (200...299).contains(code) else {
                let bodyStr = String(data: data, encoding: .utf8) ?? ""
                print("[TranslationService] Error body: \(bodyStr)")
                return lines.map { LyricTranslation(original: $0, literal: "", natural: "") }
            }

            let decoded = try JSONDecoder().decode(TranslationResponse.self, from: data)
            print("[TranslationService] Success: \(decoded.translations.count) translations")
            return decoded.translations
        } catch {
            print("[TranslationService] Exception: \(error)")
            return lines.map { LyricTranslation(original: $0, literal: "", natural: "") }
        }
    }
}

private struct TranslationResponse: Codable {
    let translations: [LyricTranslation]
}
