import Foundation

struct SpotifyTrack: Identifiable {
    let id: String
    let name: String
    let artist: String
    let albumName: String
    let imageURL: URL?
    let durationMs: Int
}

final class SpotifyService {
    static let shared = SpotifyService()

    private var accessToken: String?
    private var tokenExpiry: Date?
    private let keyManager = APIKeyManager.shared

    var isConfigured: Bool {
        keyManager.hasSpotifyKeys
    }

    private func ensureToken() async throws {
        if let token = accessToken, let expiry = tokenExpiry, Date() < expiry {
            return
        }
        guard let clientID = keyManager.get(.spotifyClientID),
              let clientSecret = keyManager.get(.spotifyClientSecret) else {
            throw SpotifyError.notConfigured
        }

        let url = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let credentials = "\(clientID):\(clientSecret)"
        let base64 = Data(credentials.utf8).base64EncodedString()
        request.setValue("Basic \(base64)", forHTTPHeaderField: "Authorization")
        request.httpBody = "grant_type=client_credentials".data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        if let error = json["error"] as? String {
            throw SpotifyError.authFailed(error)
        }
        guard let token = json["access_token"] as? String else {
            throw SpotifyError.authFailed("토큰을 받지 못했습니다")
        }

        accessToken = token
        let expiresIn = json["expires_in"] as? Int ?? 3600
        tokenExpiry = Date().addingTimeInterval(TimeInterval(expiresIn) - 60)
    }

    func search(query: String, limit: Int = 15) async throws -> [SpotifyTrack] {
        try await ensureToken()
        guard let token = accessToken else { throw SpotifyError.notConfigured }

        var components = URLComponents(string: "https://api.spotify.com/v1/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "track"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        guard let url = components.url else { return [] }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        guard let tracks = json["tracks"] as? [String: Any],
              let items = tracks["items"] as? [[String: Any]] else { return [] }

        return items.compactMap { item in
            guard let id = item["id"] as? String,
                  let name = item["name"] as? String else { return nil }
            let artists = item["artists"] as? [[String: Any]]
            let artist = artists?.first?["name"] as? String ?? ""
            let album = item["album"] as? [String: Any]
            let albumName = album?["name"] as? String ?? ""
            let images = album?["images"] as? [[String: Any]]
            let imageURLString = images?.first?["url"] as? String
            let imageURL = imageURLString.flatMap { URL(string: $0) }
            let duration = item["duration_ms"] as? Int ?? 0
            return SpotifyTrack(id: id, name: name, artist: artist, albumName: albumName, imageURL: imageURL, durationMs: duration)
        }
    }

    func downloadImage(url: URL) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }

    enum SpotifyError: LocalizedError {
        case notConfigured
        case authFailed(String)

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "Spotify API 키가 설정되지 않았습니다. 설정에서 입력해주세요."
            case .authFailed(let msg):
                return "Spotify 인증 실패: \(msg)"
            }
        }
    }
}
