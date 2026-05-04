import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    private let keyManager = APIKeyManager.shared

    @State private var spotifyClientID = ""
    @State private var spotifyClientSecret = ""
    @State private var youtubeAPIKey = ""
    @State private var showSaved = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureInputField(title: "Client ID", text: $spotifyClientID, hasExisting: keyManager.get(.spotifyClientID) != nil)
                    SecureInputField(title: "Client Secret", text: $spotifyClientSecret, hasExisting: keyManager.get(.spotifyClientSecret) != nil)
                } header: {
                    Label("Spotify API", systemImage: "music.note")
                } footer: {
                    Text("Spotify Developer Dashboard에서 앱을 생성하고 Client ID와 Secret을 발급받으세요.")
                }

                Section {
                    SecureInputField(title: "API Key", text: $youtubeAPIKey, hasExisting: keyManager.get(.youtubeAPIKey) != nil)
                } header: {
                    Label("YouTube Data API v3", systemImage: "play.rectangle")
                } footer: {
                    Text("Google Cloud Console에서 YouTube Data API v3를 활성화하고 API 키를 발급받으세요. (선택사항)")
                }

                Section {
                    HStack {
                        Label("LRCLIB", systemImage: "text.quote")
                        Spacer()
                        Text("API 키 불필요")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                } header: {
                    Text("가사 검색")
                } footer: {
                    Text("LRCLIB은 무료 가사 검색 서비스로 별도 설정이 필요 없습니다.")
                }

                Section {
                    Button(role: .destructive) {
                        for type in APIKeyManager.KeyType.allCases {
                            keyManager.delete(type)
                        }
                        spotifyClientID = ""
                        spotifyClientSecret = ""
                        youtubeAPIKey = ""
                    } label: {
                        Label("모든 API 키 삭제", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("API 설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { saveKeys() }.bold()
                }
            }
            .overlay {
                if showSaved { savedToast }
            }
        }
    }

    private func saveKeys() {
        if !spotifyClientID.isEmpty { keyManager.save(key: spotifyClientID, for: .spotifyClientID) }
        if !spotifyClientSecret.isEmpty { keyManager.save(key: spotifyClientSecret, for: .spotifyClientSecret) }
        if !youtubeAPIKey.isEmpty { keyManager.save(key: youtubeAPIKey, for: .youtubeAPIKey) }
        spotifyClientID = ""
        spotifyClientSecret = ""
        youtubeAPIKey = ""
        withAnimation { showSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showSaved = false }
        }
    }

    private var savedToast: some View {
        VStack {
            Spacer()
            Text("저장되었습니다")
                .font(.subheadline.bold())
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.thinMaterial, in: Capsule())
                .padding(.bottom, 40)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

struct SecureInputField: View {
    let title: String
    @Binding var text: String
    let hasExisting: Bool
    @State private var isSecure = true

    var body: some View {
        HStack {
            if isSecure {
                SecureField(hasExisting ? "\(title) (설정됨)" : title, text: $text)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
            } else {
                TextField(hasExisting ? "\(title) (설정됨)" : title, text: $text)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
            }
            Button { isSecure.toggle() } label: {
                Image(systemName: isSecure ? "eye.slash" : "eye").foregroundStyle(.secondary)
            }.buttonStyle(.plain)
            if hasExisting && text.isEmpty {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.caption)
            }
        }
    }
}

#Preview {
    SettingsView()
}
