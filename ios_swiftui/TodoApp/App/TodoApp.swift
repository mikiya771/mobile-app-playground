import SwiftUI
import SwiftData

@main
struct TodoApp: App {
    let container: ModelContainer = {
        let schema = Schema([TodoItem.self])
        return try! ModelContainer(for: schema)
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
