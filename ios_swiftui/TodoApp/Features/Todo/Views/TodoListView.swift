import SwiftUI

struct TodoListView: View {
    @State var viewModel: TodoListViewModel
    @State private var showForm = false
    @State private var editingTodo: Todo? = nil
    @Environment(AppRouter.self) private var router
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else {
                list
            }
        }
        .navigationTitle("Todo")
        .toolbar { toolbar }
        .sheet(isPresented: $showForm) {
            TodoFormView(editingTodo: editingTodo) { todo in
                Task { await viewModel.saveTodo(todo) }
            }
        }
        .alert("エラー", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task { await viewModel.load() }
    }

    private var list: some View {
        List {
            ForEach(viewModel.filteredTodos) { todo in
                TodoCard(todo: todo) {
                    Task { await viewModel.toggle(id: todo.id) }
                }
                .onTapGesture { router.push(.todoDetail(id: todo.id)) }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task { await viewModel.delete(id: todo.id) }
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        editingTodo = todo
                        showForm = true
                    } label: {
                        Label("編集", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
        }
        .listStyle(.plain)
        .safeAreaInset(edge: .top, spacing: 0) {
            FilterTabBar(selection: $viewModel.filter)
                .padding(.vertical, 8)
                .background(.bar)
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                editingTodo = nil
                showForm = true
            } label: {
                Image(systemName: "plus")
            }
        }
        ToolbarItem(placement: .secondaryAction) {
            Button {
                Task { await viewModel.syncFromAPI() }
            } label: {
                if viewModel.isSyncing {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Label("API同期", systemImage: "arrow.triangle.2.circlepath")
                }
            }
        }
        ToolbarItem(placement: .topBarLeading) {
            Button("ログアウト") { authViewModel.logout() }
                .foregroundStyle(.red)
        }
    }
}
