import SwiftUI
import SwiftData

struct AppContainer {
    static var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Song.self,
            LyricLine.self,
            VocabEntry.self,
            WordAppearance.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("ModelContainer 생성 실패: \(error)")
        }
    }()
}
