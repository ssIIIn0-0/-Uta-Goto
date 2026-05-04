import Foundation
import MusicKit

struct AppleMusicSearchResult: Identifiable {
    let id: String
    let title: String
    let artist: String
    let albumTitle: String
    let duration: TimeInterval?
    let artworkURL: URL?
    let hasLyrics: Bool
    let musicKitSong: MusicKit.Song
}

struct TimedLyricLine {
    let text: String
    let startTime: Double?
    let endTime: Double?
}

final class AppleMusicService {
    static let shared = AppleMusicService()

    var isAuthorized: Bool {
        MusicAuthorization.currentStatus == .authorized
    }

    func requestAuthorization() async -> Bool {
        let status = await MusicAuthorization.request()
        return status == .authorized
    }

    // MARK: - Search

    func search(query: String, limit: Int = 20) async throws -> [AppleMusicSearchResult] {
        var request = MusicCatalogSearchRequest(term: query, types: [MusicKit.Song.self])
        request.limit = limit

        let response = try await request.response()

        return response.songs.map { song in
            let artworkURL = song.artwork?.url(width: 300, height: 300)
            return AppleMusicSearchResult(
                id: song.id.rawValue,
                title: song.title,
                artist: song.artistName,
                albumTitle: song.albumTitle ?? "",
                duration: song.duration,
                artworkURL: artworkURL,
                hasLyrics: song.hasLyrics,
                musicKitSong: song
            )
        }
    }

    // MARK: - Fetch MusicKit Song by ID

    func fetchSong(id: String) async throws -> MusicKit.Song? {
        let request = MusicCatalogResourceRequest<MusicKit.Song>(matching: \.id, equalTo: MusicItemID(rawValue: id))
        let response = try await request.response()
        return response.items.first
    }

    // MARK: - Lyrics

    func fetchLyrics(songID: String) async throws -> [TimedLyricLine] {
        let storefront = try await currentStorefront()
        let url = URL(string: "https://api.music.apple.com/v1/catalog/\(storefront)/songs/\(songID)/lyrics")!
        let request = MusicDataRequest(urlRequest: URLRequest(url: url))
        let response = try await request.response()

        guard let jsonObject = try? JSONSerialization.jsonObject(with: response.data) as? [String: Any],
              let dataArray = jsonObject["data"] as? [[String: Any]],
              let first = dataArray.first,
              let attributes = first["attributes"] as? [String: Any],
              let ttml = attributes["ttml"] as? String else {
            return []
        }

        return parseTTML(ttml)
    }

    // MARK: - Artwork

    func downloadArtwork(url: URL) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }

    // MARK: - Storefront

    private func currentStorefront() async throws -> String {
        let url = URL(string: "https://api.music.apple.com/v1/me/storefront")!
        let request = MusicDataRequest(urlRequest: URLRequest(url: url))
        let response = try await request.response()

        if let jsonObject = try? JSONSerialization.jsonObject(with: response.data) as? [String: Any],
           let dataArray = jsonObject["data"] as? [[String: Any]],
           let first = dataArray.first,
           let id = first["id"] as? String {
            return id
        }

        return Locale.current.region?.identifier.lowercased() ?? "us"
    }

    // MARK: - TTML Parser

    private func parseTTML(_ ttml: String) -> [TimedLyricLine] {
        guard let data = ttml.data(using: .utf8) else { return [] }
        let parser = TTMLParser()
        return parser.parse(data: data)
    }
}

// MARK: - TTML XML Parser

private final class TTMLParser: NSObject, XMLParserDelegate {
    private var lines: [TimedLyricLine] = []
    private var currentText = ""
    private var currentBegin: Double?
    private var currentEnd: Double?
    private var insideP = false

    func parse(data: Data) -> [TimedLyricLine] {
        lines = []
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return lines
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]) {
        if elementName == "p" || elementName.hasSuffix(":p") {
            insideP = true
            currentText = ""
            currentBegin = attributes["begin"].flatMap { parseTimestamp($0) }
            currentEnd = attributes["end"].flatMap { parseTimestamp($0) }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if insideP {
            currentText += string
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        if elementName == "p" || elementName.hasSuffix(":p") {
            let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                lines.append(TimedLyricLine(text: trimmed, startTime: currentBegin, endTime: currentEnd))
            }
            insideP = false
        }
    }

    private func parseTimestamp(_ value: String) -> Double? {
        // Formats: "00:15.000", "00:01:15.000", "15000ms", "15.0s"
        if value.hasSuffix("ms") {
            let num = String(value.dropLast(2))
            return Double(num).map { $0 / 1000.0 }
        }
        if value.hasSuffix("s") {
            let num = String(value.dropLast(1))
            return Double(num)
        }

        let parts = value.components(separatedBy: ":")
        switch parts.count {
        case 2:
            guard let mins = Double(parts[0]),
                  let secs = Double(parts[1]) else { return nil }
            return mins * 60 + secs
        case 3:
            guard let hrs = Double(parts[0]),
                  let mins = Double(parts[1]),
                  let secs = Double(parts[2]) else { return nil }
            return hrs * 3600 + mins * 60 + secs
        default:
            return Double(value)
        }
    }
}
