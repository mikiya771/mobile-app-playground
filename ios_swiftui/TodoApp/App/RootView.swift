import SwiftUI
import SwiftData

// Step 7: SwiftData の ModelContext を取得して ViewModel を生成する
// Step 9 で AuthGuard に置き換わる
struct RootView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            TodoListView(viewModel: TodoListViewModel(repository: makeRepository()))
        }
    }

    private func makeRepository() -> TodoRepositoryInterface {
        TodoRepository(context: context)
    }
}
