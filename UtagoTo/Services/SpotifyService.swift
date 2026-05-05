import Foundation

struct SearchTrack: Identifiable {
    let id: String
    let name: String
    let artist: String
    let albumName: String
    let imageURL: URL?
    let durationMs: Int
}

final class ITunesSearchService {
    static let shared = ITunesSearchService()

    func search(query: String, limit: Int = 15) async throws -> [SearchTrack] {
        var components = URLComponents(string: "https://itunes.apple.com/search")!
        components.queryItems = [
            URLQueryItem(name: "term", value: query),
            URLQueryItem(name: "media", value: "music"),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        guard let url = components.url else { return [] }

        let (data, response) = try await URLSession.shared.data(from: url)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw SearchError.requestFailed("HTTP \(httpResponse.statusCode)")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]] else {
            return []
        }

        return results.compactMap { item in
            guard let trackId = item["trackId"] as? Int,
                  let name = item["trackName"] as? String else { return nil }
            let artist = item["artistName"] as? String ?? ""
            let albumName = item["collectionName"] as? String ?? ""
            let artworkURLString = (item["artworkUrl100"] as? String)?
                .replacingOccurrences(of: "100x100", with: "600x600")
            let imageURL = artworkURLString.flatMap { URL(string: $0) }
            let duration = item["trackTimeMillis"] as? Int ?? 0
            return SearchTrack(
                id: "\(trackId)",
                name: name,
                artist: artist,
                albumName: albumName,
                imageURL: imageURL,
                durationMs: duration
            )
        }
    }

    func downloadImage(url: URL) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }

    enum SearchError: LocalizedError {
        case requestFailed(String)

        var errorDescription: String? {
            switch self {
            case .requestFailed(let msg):
                return "검색 실패: \(msg)"
            }
        }
    }
}
