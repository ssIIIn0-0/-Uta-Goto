import SwiftUI
import MusicKit

struct SongSearchView: View {
    @Environment(\.dismiss) private var dismiss

    var onSave: (String, String, String, [String], String?, Data?) -> Void

    @State private var searchQuery = ""
    @State private var searchResults: [AppleMusicSearchResult] = []
    @State private var isSearching = false
    @State private var searchError: String?

    @State private var selectedResult: AppleMusicSearchResult?
    @State private var lrcContent = ""
    @State private var translationText = ""
    @State private var includeTranslation = false
    @State private var thumbnailData: Data?
    @State private var isFetchingLyrics = false
    @State private var lyricsFound = false
    @State private var showManualLRC = false

    private let appleMusic = AppleMusicService.shared

    var body: some View {
        NavigationStack {
            Group {
                if let result = selectedResult {
                    songDetailView(result)
                } else {
                    searchListView
                }
            }
            .navigationTitle(selectedResult == nil ? "노래 검색" : "노래 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(selectedResult == nil ? "취소" : "뒤로") {
                        if selectedResult != nil {
                            selectedResult = nil
                            lrcContent = ""
                            translationText = ""
                            thumbnailData = nil
                            lyricsFound = false
                            showManualLRC = false
                        } else {
                            dismiss()
                        }
                    }
                }
                if selectedResult != nil {
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
            if !appleMusic.isAuthorized {
                Section {
                    Button {
                        Task {
                            await appleMusic.requestAuthorization()
                        }
                    } label: {
                        Label("Apple Music 접근 권한이 필요합니다. 탭하여 허용해주세요.", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
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
                    HStack {
                        Spacer()
                        ProgressView("검색 중...")
                        Spacer()
                    }
                }
            } else if let error = searchError {
                Section {
                    Label(error, systemImage: "exclamationmark.circle")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            } else if !searchResults.isEmpty {
                Section("검색 결과") {
                    ForEach(searchResults) { result in
                        Button {
                            selectResult(result)
                        } label: {
                            AppleMusicTrackRow(result: result)
                        }
                        .tint(.primary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Song Detail

    private func songDetailView(_ result: AppleMusicSearchResult) -> some View {
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
                        Text(result.title)
                            .font(.headline)
                        Text(result.artist)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(result.albumTitle)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Section {
                if isFetchingLyrics {
                    HStack {
                        ProgressView()
                        Text("Apple Music에서 가사 가져오는 중...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else if lyricsFound {
                    Label("동기화 가사를 찾았습니다", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline)

                    DisclosureGroup("가사 확인/편집") {
                        TextEditor(text: $lrcContent)
                            .font(.system(.caption, design: .monospaced))
                            .frame(minHeight: 200)
                    }
                } else {
                    Label("가사를 찾지 못했습니다", systemImage: "exclamationmark.circle")
                        .foregroundStyle(.orange)
                        .font(.subheadline)

                    Button("LRC 가사 직접 입력") {
                        showManualLRC = true
                    }

                    if showManualLRC {
                        TextEditor(text: $lrcContent)
                            .font(.system(.caption, design: .monospaced))
                            .frame(minHeight: 200)
                    }
                }
            } header: {
                Text("가사 (LRC)")
            }

            Section {
                Toggle("한국어 번역 포함", isOn: $includeTranslation)
                if includeTranslation {
                    TextEditor(text: $translationText)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 100)
                }
            } header: {
                Text("번역")
            } footer: {
                if includeTranslation {
                    Text("가사와 같은 줄 수로 입력하세요.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
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
                if !appleMusic.isAuthorized {
                    let authorized = await appleMusic.requestAuthorization()
                    if !authorized {
                        await MainActor.run {
                            searchError = "Apple Music 접근 권한이 필요합니다."
                            isSearching = false
                        }
                        return
                    }
                }

                let results = try await appleMusic.search(query: query)
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    searchError = error.localizedDescription
                    isSearching = false
                }
            }
        }
    }

    private func selectResult(_ result: AppleMusicSearchResult) {
        selectedResult = result

        if let artworkURL = result.artworkURL {
            Task {
                if let data = try? await appleMusic.downloadArtwork(url: artworkURL) {
                    await MainActor.run { thumbnailData = data }
                }
            }
        }

        Task {
            await MainActor.run { isFetchingLyrics = true }
            do {
                let timedLines = try await appleMusic.fetchLyrics(songID: result.id)
                if !timedLines.isEmpty {
                    let lrc = timedLines.map { line -> String in
                        if let start = line.startTime {
                            let mins = Int(start) / 60
                            let secs = start - Double(mins * 60)
                            return String(format: "[%02d:%05.2f]%@", mins, secs, line.text)
                        }
                        return line.text
                    }.joined(separator: "\n")

                    await MainActor.run {
                        lrcContent = lrc
                        lyricsFound = true
                        isFetchingLyrics = false
                    }
                } else {
                    await MainActor.run { isFetchingLyrics = false }
                }
            } catch {
                await MainActor.run { isFetchingLyrics = false }
            }
        }
    }

    private func saveAction() {
        guard let result = selectedResult else { return }
        let trimmedLRC = lrcContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLRC.isEmpty else { return }

        let translations: [String]
        if includeTranslation {
            translations = translationText.components(separatedBy: .newlines)
        } else {
            translations = []
        }

        onSave(
            result.title,
            result.artist,
            trimmedLRC,
            translations,
            result.id,
            thumbnailData
        )

        dismiss()
    }
}

// MARK: - Apple Music Track Row

struct AppleMusicTrackRow: View {
    let result: AppleMusicSearchResult

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: result.artworkURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray5))
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(result.title)
                    .font(.subheadline)
                    .lineLimit(1)
                Text(result.artist)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if result.hasLyrics {
                Image(systemName: "text.quote")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }

            if let duration = result.duration {
                Text(formatDuration(duration))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

#Preview {
    SongSearchView { _, _, _, _, _, _ in }
}
