import SwiftUI
import SwiftData

@main
struct UtagoToApp: App {
    @State private var playerVM = PlayerViewModel()
    @State private var vocabVM = VocabViewModel()
    @State private var selectedTab = 0

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                LibraryView { song in
                    playerVM.loadSong(song)
                    selectedTab = 1
                }
                .tabItem {
                    Label("라이브러리", systemImage: "music.note.list")
                }
                .tag(0)

                PlayerView(playerVM: playerVM, vocabVM: vocabVM)
                    .tabItem {
                        Label("플레이어", systemImage: "play.circle.fill")
                    }
                    .tag(1)

                VocabListView(vocabVM: vocabVM) { song in
                    playerVM.loadSong(song)
                    selectedTab = 1
                }
                .tabItem {
                    Label("단어장", systemImage: "book.fill")
                }
                .tag(2)
            }
            .tint(Color(red: 0.36, green: 0.42, blue: 0.75))
        }
        .modelContainer(AppContainer.sharedModelContainer)
    }
}
