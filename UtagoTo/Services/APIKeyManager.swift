import Foundation
import Security

final class APIKeyManager {
    static let shared = APIKeyManager()

    private let serviceName = "com.utagoto.apikeys"

    enum KeyType: String, CaseIterable {
        case youtubeAPIKey = "youtube_api_key"

        var displayName: String {
            switch self {
            case .youtubeAPIKey: return "YouTube API Key"
            }
        }
    }

    func save(key: String, for type: KeyType) {
        let data = Data(key.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: type.rawValue
        ]
        SecItemDelete(query as CFDictionary)
        var addQuery = query
        addQuery[kSecValueData as String] = data
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    func get(_ type: KeyType) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: type.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func delete(_ type: KeyType) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: type.rawValue
        ]
        SecItemDelete(query as CFDictionary)
    }

    var hasYouTubeKey: Bool {
        self.get(.youtubeAPIKey) != nil
    }
}
