import Foundation

struct YouTubeVideo: Identifiable {
    let id: String
    let title: String
    let channelTitle: String

    var youtubeMusicAppURL: URL? {
        URL(string: "youtubemusic://watch?v=\(id)")
    }

    var youtubeMusicWebURL: URL? {
        URL(string: "https://music.youtube.com/watch?v=\(id)")
    }
}

final class YouTubeService {
    static let shared = YouTubeService()
    private let keyManager = APIKeyManager.shared

    var isConfigured: Bool {
        keyManager.hasYouTubeKey
    }

    func search(query: String, maxResults: Int = 1) async throws -> [YouTubeVideo] {
        guard let apiKey = keyManager.get(.youtubeAPIKey) else {
            throw YouTubeError.notConfigured
        }

        var components = URLComponents(string: "https://www.googleapis.com/youtube/v3/search")!
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "videoCategoryId", value: "10"),
            URLQueryItem(name: "maxResults", value: "\(maxResults)"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        guard let url = components.url else { return [] }

        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            throw YouTubeError.apiFailed(message)
        }

        guard let items = json["items"] as? [[String: Any]] else { return [] }

        return items.compactMap { item in
            guard let idObj = item["id"] as? [String: Any],
                  let videoId = idObj["videoId"] as? String,
                  let snippet = item["snippet"] as? [String: Any] else { return nil }
            return YouTubeVideo(
                id: videoId,
                title: snippet["title"] as? String ?? "",
                channelTitle: snippet["channelTitle"] as? String ?? ""
            )
        }
    }

    enum YouTubeError: LocalizedError {
        case notConfigured
        case apiFailed(String)

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "YouTube API 키가 설정되지 않았습니다. 설정에서 입력해주세요."
            case .apiFailed(let msg):
                return "YouTube API 오류: \(msg)"
            }
        }
    }
}
