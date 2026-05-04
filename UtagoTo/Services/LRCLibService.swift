import Foundation

struct LRCLibResult: Decodable, Identifiable {
    let id: Int
    let trackName: String
    let artistName: String
    let albumName: String?
    let duration: Double?
    let syncedLyrics: String?
    let plainLyrics: String?
}

final class LRCLibService {
    static let shared = LRCLibService()
    private let baseURL = "https://lrclib.net/api"

    func search(track: String, artist: String) async throws -> [LRCLibResult] {
        var components = URLComponents(string: "\(baseURL)/search")!
        components.queryItems = [
            URLQueryItem(name: "track_name", value: track),
            URLQueryItem(name: "artist_name", value: artist)
        ]
        guard let url = components.url else { return [] }
        var request = URLRequest(url: url)
        request.setValue("UtagoTo/1.0", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([LRCLibResult].self, from: data)
    }

    func searchByQuery(_ query: String) async throws -> [LRCLibResult] {
        var components = URLComponents(string: "\(baseURL)/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query)
        ]
        guard let url = components.url else { return [] }
        var request = URLRequest(url: url)
        request.setValue("UtagoTo/1.0", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([LRCLibResult].self, from: data)
    }
}
