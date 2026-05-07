import SwiftUI
import SwiftData

// Step 8: NavigationStack + AppRouter でマルチ画面を構成
// Step 9 で AuthGuard を追加する
struct RootView: View {
    @Environment(\.modelContext) private var context
    @State private var router = AppRouter()

    var body: some View {
        // Step 9 でここを AuthGuard に置き換える
        NavigationStack(path: $router.path) {
            TodoListView(viewModel: TodoListViewModel(repository: makeRepository()))
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .todoDetail(let id):
                        TodoDetailWebView(todoId: id)
                    case .todoForm(let todo):
                        TodoFormView(editingTodo: todo, onSave: { _ in router.pop() })
                    }
                }
        }
        .environment(router)
    }

    private func makeRepository() -> TodoRepositoryInterface {
        TodoRepository(context: context)
    }
}
