import SwiftUI
import SwiftData

// Step 9: AuthGuard
// go_router の redirect に相当する isLoggedIn による分岐
struct RootView: View {
    @Environment(\.modelContext) private var context
    @State private var router = AppRouter()
    @State private var authViewModel = AuthViewModel()

    var body: some View {
        Group {
            if authViewModel.isLoggedIn {
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
            } else {
                LoginView()
            }
        }
        .environment(router)
        .environment(authViewModel)
        .task { authViewModel.initialize() }
    }

    private func makeRepository() -> TodoRepositoryInterface {
        TodoRepository(context: context)
    }
}
