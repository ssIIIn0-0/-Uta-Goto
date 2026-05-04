import SwiftUI
import MusicKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var musicAuthStatus = MusicAuthorization.currentStatus

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: "apple.logo")
                        Text("Apple Music")
                            .font(.headline)
                        Spacer()
                        statusBadge
                    }

                    if musicAuthStatus != .authorized {
                        Button("Apple Music 권한 요청") {
                            Task {
                                musicAuthStatus = await MusicAuthorization.request()
                            }
                        }
                    }
                } header: {
                    Text("음악 서비스")
                } footer: {
                    switch musicAuthStatus {
                    case .authorized:
                        Text("Apple Music에서 곡 검색, 가사 가져오기, 음원 재생이 가능합니다.")
                    case .denied:
                        Text("설정 앱 > 개인정보 보호 > 미디어 및 Apple Music에서 권한을 허용해주세요.")
                    case .restricted:
                        Text("이 기기에서 Apple Music 접근이 제한되어 있습니다.")
                    case .notDetermined:
                        Text("Apple Music 접근 권한을 요청하면 곡 검색과 재생이 가능합니다.")
                    @unknown default:
                        EmptyView()
                    }
                }

                Section {
                    HStack {
                        Text("Apple Music 구독")
                        Spacer()
                        Text("전체 재생에 필요")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("Apple Music 구독이 없으면 미리듣기만 가능합니다. 가사 검색과 단어 학습은 구독 없이도 사용할 수 있습니다.")
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch musicAuthStatus {
        case .authorized:
            Label("연결됨", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
        case .denied:
            Label("거부됨", systemImage: "xmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.red)
        case .restricted:
            Label("제한됨", systemImage: "exclamationmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.orange)
        case .notDetermined:
            Label("미설정", systemImage: "questionmark.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
        @unknown default:
            EmptyView()
        }
    }
}

#Preview {
    SettingsView()
}
