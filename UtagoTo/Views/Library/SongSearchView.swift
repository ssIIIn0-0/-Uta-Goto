import SwiftUI

struct SongSearchView: View {
    @Environment(\.dismiss) private var dismiss

    var onSave: (String, String, String, [String], String?, Data?) -> Void

    @State private var searchQuery = ""
    @State private var searchResults: [SearchTrack] = []
    @State private var isSearching = false
    @State private var searchError: String?

    @State private var selectedTrack: SearchTrack?
    @State private var lrcContent = ""
    @State private var translations: [String] = []
    @State private var youtubeURL: String?
    @State private var thumbnailData: Data?
    @State private var isFetchingLyrics = false
    @State private var isFetchingYouTube = false
    @State private var isTranslating = false
    @State private var lyricsFound = false
    @State private var showManualLRC = false
    @State private var translationError: String?

    private let iTunes = ITunesSearchService.shared
    private let lrcLib = LRCLibService.shared
    private let youtube = YouTubeService.shared
    private let translator = TranslationService.shared

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
                            translations = []
                            youtubeURL = nil
                            thumbnailData = nil
                            lyricsFound = false
                            showManualLRC = false
                            isTranslating = false
                            translationError = nil
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
            } else if !searchResults.isEmpty {
                Section("검색 결과") {
                    ForEach(searchResults) { track in
                        Button { selectTrack(track) } label: {
                            SearchTrackRow(track: track)
                        }
                        .tint(.primary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Song Detail

    private func songDetailView(_ track: SearchTrack) -> some View {
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
                if isTranslating {
                    HStack {
                        ProgressView()
                        Text("한국어 번역 중...").font(.subheadline).foregroundStyle(.secondary)
                    }
                } else if translations.contains(where: { !$0.isEmpty }) {
                    Label("한국어 번역 완료", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green).font(.subheadline)
                } else if lyricsFound || !lrcContent.isEmpty {
                    Button("한국어 번역하기") { translateLyrics() }
                    if translationError != nil {
                        Label("번역 실패 — 다시 시도해주세요", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange).font(.caption)
                    }
                }
            } header: { Text("번역") }

            if youtubeURL != nil {
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
        searchResults = []

        Task {
            do {
                let results = try await iTunes.search(query: query)
                await MainActor.run { searchResults = results; isSearching = false }
            } catch {
                await MainActor.run { searchError = error.localizedDescription; isSearching = false }
            }
        }
    }

    private func selectTrack(_ track: SearchTrack) {
        selectedTrack = track

        if let imageURL = track.imageURL {
            Task {
                if let data = try? await iTunes.downloadImage(url: imageURL) {
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
                        translateLyrics()
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
                        youtubeURL = results.first?.youtubeMusicWebURL?.absoluteString
                        isFetchingYouTube = false
                    }
                } catch {
                    await MainActor.run { isFetchingYouTube = false }
                }
            }
        }
    }

    private func translateLyrics() {
        let lines = lrcContent
            .components(separatedBy: .newlines)
            .map { line in
                line.replacingOccurrences(
                    of: "^\\[\\d{2}:\\d{2}\\.\\d{2,3}\\]",
                    with: "",
                    options: .regularExpression
                ).trimmingCharacters(in: .whitespaces)
            }

        isTranslating = true
        translationError = nil
        Task {
            let result = await translator.translate(lines: lines)
            await MainActor.run {
                translations = result
                isTranslating = false
                if !result.contains(where: { !$0.isEmpty }) {
                    translationError = "번역 실패"
                    translations = []
                }
            }
        }
    }

    private func saveAction() {
        guard let track = selectedTrack else { return }
        let trimmedLRC = lrcContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLRC.isEmpty else { return }

        onSave(track.name, track.artist, trimmedLRC, translations, youtubeURL, thumbnailData)
        dismiss()
    }
}

// MARK: - Search Track Row

struct SearchTrackRow: View {
    let track: SearchTrack

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
