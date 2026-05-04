import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = LibraryViewModel()
    @State private var showAddSong = false
    @State private var showSearchSong = false
    @State private var showSettings = false

    var onSelectSong: ((Song) -> Void)?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.songs.isEmpty {
                    EmptyStateView(
                        icon: "music.note",
                        title: "노래가 없습니다",
                        message: "오른쪽 상단 + 버튼으로 노래를 추가해보세요."
                    )
                } else {
                    List {
                        ForEach(viewModel.songs, id: \.id) { song in
                            SongRowView(
                                song: song,
                                distribution: viewModel.jlptDistribution(for: song)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture { onSelectSong?(song) }
                        }
                        .onDelete { offsets in viewModel.deleteSongs(at: offsets) }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("나의 노래")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("설정")
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button { showSearchSong = true } label: {
                            Label("검색으로 추가", systemImage: "magnifyingglass")
                        }
                        Button { showAddSong = true } label: {
                            Label("수동으로 추가", systemImage: "square.and.pencil")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("노래 추가")
                }
            }
            .sheet(isPresented: $showAddSong) {
                AddSongView { title, artist, lrc, translations, audioFile, audioURL in
                    viewModel.addSong(
                        title: title, artist: artist, lrcContent: lrc,
                        translations: translations, audioFileName: audioFile,
                        audioURLString: audioURL
                    )
                }
            }
            .sheet(isPresented: $showSearchSong) {
                SongSearchView { title, artist, lrc, translations, youtubeURL, thumbnail in
                    viewModel.addSong(
                        title: title, artist: artist, lrcContent: lrc,
                        translations: translations,
                        youtubeURLString: youtubeURL, thumbnailData: thumbnail
                    )
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onAppear {
                viewModel.setup(context: modelContext)
                viewModel.fetchSongs()
            }
            .alert("오류", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

#Preview {
    LibraryView()
        .modelContainer(SampleData.previewContainer)
}
