import SwiftUI
import SwiftData

struct PlayerView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var playerVM: PlayerViewModel
    @Bindable var vocabVM: VocabViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let song = playerVM.currentSong {
                    songHeader(song)
                    jlptLegend
                    Divider()

                    LyricScrollView(
                        lines: playerVM.sortedLines,
                        tokenizedLines: playerVM.tokenizedLines,
                        activeLineIndex: playerVM.audioService.activeLineIndex,
                        showTranslation: playerVM.showTranslation
                    ) { token, lineIndex in
                        handleTokenTap(token, lineIndex: lineIndex, song: song)
                    }

                    if let ytURL = song.youtubeURL {
                        Divider()
                        youtubeMusicButton(url: ytURL)
                    }

                    if playerVM.audioService.hasAudio {
                        Divider()
                        audioControls
                    }
                } else {
                    EmptyStateView(
                        icon: "play.circle",
                        title: "재생 중인 노래 없음",
                        message: "라이브러리에서 노래를 선택해주세요."
                    )
                }
            }
            .navigationTitle("플레이어")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Toggle("번역 표시", isOn: $playerVM.showTranslation)
                        Toggle("로마자 표시", isOn: $playerVM.showRomaji)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("표시 옵션")
                }
            }
            .sheet(isPresented: $playerVM.showWordDetail) {
                if let token = playerVM.selectedWord {
                    WordDetailSheet(
                        token: token,
                        currentSong: playerVM.currentSong,
                        vocabVM: vocabVM,
                        lineIndex: findLineIndex(for: token),
                        lineText: findLineText(for: token)
                    )
                    .presentationDetents([.medium])
                }
            }
            .alert("오디오 오류", isPresented: .init(
                get: { playerVM.audioService.errorMessage != nil },
                set: { if !$0 { playerVM.audioService.errorMessage = nil } }
            )) {
                Button("재시도") {
                    if let song = playerVM.currentSong {
                        playerVM.audioService.load(song: song)
                    }
                }
                Button("확인", role: .cancel) {}
            } message: {
                Text(playerVM.audioService.errorMessage ?? "")
            }
        }
    }

    @ViewBuilder
    private func songHeader(_ song: Song) -> some View {
        VStack(spacing: 8) {
            if let data = song.thumbnailData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray5))
                    .frame(width: 180, height: 180)
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: 50))
                            .foregroundStyle(.secondary)
                    }
            }

            Text(song.title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text(song.artist)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var jlptLegend: some View {
        HStack(spacing: 12) {
            ForEach([JLPTLevel.n5, .n4, .n3, .n2, .n1], id: \.self) { level in
                HStack(spacing: 4) {
                    Circle()
                        .fill(level.color)
                        .frame(width: 8, height: 8)
                    Text(level.displayName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("JLPT \(level.displayName) \(level.colorName)")
            }
        }
        .padding(.vertical, 6)
    }

    private func youtubeMusicButton(url: URL) -> some View {
        Button {
            UIApplication.shared.open(url)
        } label: {
            HStack {
                Image(systemName: "play.rectangle.fill")
                    .foregroundStyle(.red)
                Text("YouTube Music에서 재생")
                    .font(.subheadline.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.bordered)
        .tint(.red)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var audioControls: some View {
        VStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: { playerVM.audioService.currentTime },
                    set: { playerVM.audioService.seek(to: $0) }
                ),
                in: 0...max(playerVM.audioService.duration, 1)
            )
            .tint(Color("AccentColor"))
            .padding(.horizontal)

            HStack {
                Text(playerVM.audioService.formatTime(playerVM.audioService.currentTime))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Spacer()
                Text(playerVM.audioService.formatTime(playerVM.audioService.duration))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding(.horizontal)

            HStack(spacing: 40) {
                Button {
                    playerVM.audioService.skipBackward()
                } label: {
                    Image(systemName: "gobackward.15")
                        .font(.title2)
                }
                .accessibilityLabel("15초 뒤로")

                Button {
                    playerVM.audioService.togglePlayPause()
                } label: {
                    Image(systemName: playerVM.audioService.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 50))
                }
                .accessibilityLabel(playerVM.audioService.isPlaying ? "일시정지" : "재생")

                Button {
                    playerVM.audioService.skipForward()
                } label: {
                    Image(systemName: "goforward.15")
                        .font(.title2)
                }
                .accessibilityLabel("15초 앞으로")
            }
            .padding(.bottom, 16)
        }
    }

    private func handleTokenTap(_ token: TokenWord, lineIndex: Int, song: Song) {
        guard token.isJapanese else { return }
        playerVM.selectWord(token)

        let lineText = lineIndex < playerVM.sortedLines.count
            ? playerVM.sortedLines[lineIndex].originalText
            : ""

        vocabVM.recordEncounter(
            token: token,
            in: song,
            lineText: lineText,
            lineIndex: lineIndex
        )
    }

    private func findLineIndex(for token: TokenWord) -> Int {
        for (lineIdx, tokens) in playerVM.tokenizedLines.enumerated() {
            if tokens.contains(where: { $0.id == token.id }) {
                return lineIdx
            }
        }
        return 0
    }

    private func findLineText(for token: TokenWord) -> String {
        let idx = findLineIndex(for: token)
        guard idx < playerVM.sortedLines.count else { return "" }
        return playerVM.sortedLines[idx].originalText
    }
}

struct WordDetailSheet: View {
    let token: TokenWord
    let currentSong: Song?
    @Bindable var vocabVM: VocabViewModel
    let lineIndex: Int
    let lineText: String

    @State private var justAdded = false

    private var dictEntry: DictionaryEntry? {
        JLPTDictionaryService.shared.entry(for: token.surface)
    }

    private var isSaved: Bool {
        vocabVM.isWordSaved(token.surface)
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                JLPTBadgeView(level: token.jlptLevel)
                Spacer()
            }

            VStack(spacing: 4) {
                Text(token.surface)
                    .font(.system(size: 36, weight: .bold))

                Text(dictEntry?.reading ?? token.reading)
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Text(dictEntry?.meaning ?? "")
                    if let pos = dictEntry?.partOfSpeech, !pos.isEmpty {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(pos)
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.body)
            }

            if !lineText.isEmpty {
                VStack(spacing: 4) {
                    Text("이 곡에서")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Divider()
                    Text("「\(lineText)」")
                        .font(.body)
                        .italic()
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                }
                .padding(.vertical, 4)
            }

            Spacer()

            if isSaved || justAdded {
                Label("이미 추가됨", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
            } else {
                Button {
                    guard let song = currentSong else { return }
                    vocabVM.recordEncounter(
                        token: token,
                        in: song,
                        lineText: lineText,
                        lineIndex: lineIndex
                    )
                    justAdded = true
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                } label: {
                    Label("단어장에 추가", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
    }
}

#Preview {
    PlayerView(
        playerVM: PlayerViewModel(),
        vocabVM: VocabViewModel()
    )
    .modelContainer(SampleData.previewContainer)
}
