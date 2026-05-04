import SwiftUI

struct SongSearchView: View {
    @Environment(\.dismiss) private var dismiss

    var onSave: (String, String, String, [String], String?, Data?) -> Void

    @State private var searchQuery = ""
    @State private var spotifyResults: [SpotifyTrack] = []
    @State private var isSearching = false
    @State private var searchError: String?

    @State private var selectedTrack: SpotifyTrack?
    @State private var lrcContent = ""
    @State private var translationText = ""
    @State private var includeTranslation = false
    @State private var youtubeURL: String?
    @State private var thumbnailData: Data?
    @State private var isFetchingLyrics = false
    @State private var isFetchingYouTube = false
    @State private var lyricsFound = false
    @State private var showManualLRC = false

    private let spotify = SpotifyService.shared
    private let lrcLib = LRCLibService.shared
    private let youtube = YouTubeService.shared

    var body: some View {
        NavigationStack {
            Group {
                if let track = selectedTrack {
                    songDetailView(track)
                } else {
                    searchListView
                }
            }
            .navigationTitle(selectedTrack == nil ? "노래 검색" : "노래 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(selectedTrack == nil ? "취소" : "뒤로") {
                        if selectedTrack != nil {
                            selectedTrack = nil
                            lrcContent = ""
                            translationText = ""
                            youtubeURL = nil
                            thumbnailData = nil
                            lyricsFound = false
                            showManualLRC = false
                        } else {
                            dismiss()
                        }
                    }
                }
                if selectedTrack != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("저장") { saveAction() }
                            .bold()
                            .disabled(lrcContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }

    // MARK: - Search List

    private var searchListView: some View {
        List {
            if !spotify.isConfigured {
                Section {
                    Label("Spotify API 키를 설정하면 곡 검색이 가능합니다.", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Section {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("제목 또는 아티스트 검색", text: $searchQuery)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onSubmit { performSearch() }
                }
            }

            if isSearching {
                Section {
                    HStack { Spacer(); ProgressView("검색 중..."); Spacer() }
                }
            } else if let error = searchError {
                Section {
                    Label(error, systemImage: "exclamationmark.circle")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            } else if !spotifyResults.isEmpty {
                Section("검색 결과") {
                    ForEach(spotifyResults) { track in
                        Button { selectTrack(track) } label: {
                            SpotifyTrackRow(track: track)
                        }
                        .tint(.primary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Song Detail

    private func songDetailView(_ track: SpotifyTrack) -> some View {
        Form {
            Section {
                HStack(spacing: 12) {
                    if let data = thumbnailData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(width: 60, height: 60)
                            .overlay {
                                Image(systemName: "music.note")
                                    .foregroundStyle(.secondary)
                            }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(track.name).font(.headline)
                        Text(track.artist).font(.subheadline).foregroundStyle(.secondary)
                        Text(track.albumName).font(.caption).foregroundStyle(.tertiary)
                    }
                }
            }

            Section {
                if isFetchingLyrics {
                    HStack {
                        ProgressView()
                        Text("가사 검색 중...").font(.subheadline).foregroundStyle(.secondary)
                    }
                } else if lyricsFound {
                    Label("동기화 가사를 찾았습니다", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green).font(.subheadline)
                    DisclosureGroup("가사 확인/편집") {
                        TextEditor(text: $lrcContent)
                            .font(.system(.caption, design: .monospaced))
                            .frame(minHeight: 200)
                    }
                } else {
                    Label("동기화 가사를 찾지 못했습니다", systemImage: "exclamationmark.circle")
                        .foregroundStyle(.orange).font(.subheadline)
                    Button("LRC 가사 직접 입력") { showManualLRC = true }
                    if showManualLRC {
                        TextEditor(text: $lrcContent)
                            .font(.system(.caption, design: .monospaced))
                            .frame(minHeight: 200)
                    }
                }
            } header: { Text("가사 (LRC)") }

            Section {
                Toggle("한국어 번역 포함", isOn: $includeTranslation)
                if includeTranslation {
                    TextEditor(text: $translationText)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 100)
                }
            } header: { Text("번역") } footer: {
                if includeTranslation {
                    Text("가사와 같은 줄 수로 입력하세요.").font(.caption).foregroundStyle(.tertiary)
                }
            }

            if let ytURL = youtubeURL {
                Section("YouTube Music") {
                    HStack {
                        Image(systemName: "play.rectangle.fill").foregroundStyle(.red)
                        Text("YouTube 링크 연결됨").font(.subheadline)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    }
                }
            } else if isFetchingYouTube {
                Section("YouTube Music") {
                    HStack {
                        ProgressView()
                        Text("YouTube 검색 중...").font(.subheadline).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func performSearch() {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        isSearching = true
        searchError = nil
        spotifyResults = []

        Task {
            do {
                let results = try await spotify.search(query: query)
                await MainActor.run { spotifyResults = results; isSearching = false }
            } catch {
                await MainActor.run { searchError = error.localizedDescription; isSearching = false }
            }
        }
    }

    private func selectTrack(_ track: SpotifyTrack) {
        selectedTrack = track

        if let imageURL = track.imageURL {
            Task {
                if let data = try? await spotify.downloadImage(url: imageURL) {
                    await MainActor.run { thumbnailData = data }
                }
            }
        }

        Task {
            await MainActor.run { isFetchingLyrics = true }
            do {
                let results = try await lrcLib.search(track: track.name, artist: track.artist)
                let synced = results.first(where: { $0.syncedLyrics != nil })
                await MainActor.run {
                    if let lyrics = synced?.syncedLyrics {
                        lrcContent = lyrics
                        lyricsFound = true
                    }
                    isFetchingLyrics = false
                }
            } catch {
                await MainActor.run { isFetchingLyrics = false }
            }
        }

        if youtube.isConfigured {
            Task {
                await MainActor.run { isFetchingYouTube = true }
                do {
                    let results = try await youtube.search(query: "\(track.name) \(track.artist)")
                    await MainActor.run {
                        youtubeURL = results.first?.youtubeMusicURL?.absoluteString
                        isFetchingYouTube = false
                    }
                } catch {
                    await MainActor.run { isFetchingYouTube = false }
                }
            }
        }
    }

    private func saveAction() {
        guard let track = selectedTrack else { return }
        let trimmedLRC = lrcContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLRC.isEmpty else { return }

        let translations: [String] = includeTranslation
            ? translationText.components(separatedBy: .newlines)
            : []

        onSave(track.name, track.artist, trimmedLRC, translations, youtubeURL, thumbnailData)
        dismiss()
    }
}

// MARK: - Spotify Track Row

struct SpotifyTrackRow: View {
    let track: SpotifyTrack

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: track.imageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 6).fill(Color(.systemGray5))
                    .overlay { Image(systemName: "music.note").font(.caption).foregroundStyle(.secondary) }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(track.name).font(.subheadline).lineLimit(1)
                Text(track.artist).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Text(formatDuration(track.durationMs)).font(.caption2).foregroundStyle(.tertiary).monospacedDigit()
        }
    }

    private func formatDuration(_ ms: Int) -> String {
        String(format: "%d:%02d", ms / 1000 / 60, ms / 1000 % 60)
    }
}

#Preview {
    SongSearchView { _, _, _, _, _, _ in }
}
