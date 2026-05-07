import SwiftUI

// Step 5 & 6: List + swipeActions + toggle
// Flutter の TodoListPage に相当（ViewModel なし、サンプルデータで動作確認）
struct TodoListView: View {
    @State private var todos = Todo.samples
    @State private var filter: TodoFilter = .all

    private var filteredTodos: [Todo] {
        switch filter {
        case .all: todos
        case .active: todos.filter { !$0.isCompleted }
        case .completed: todos.filter { $0.isCompleted }
        }
    }

    var body: some View {
        List {
            ForEach(filteredTodos) { todo in
                TodoCard(todo: todo) {
                    toggle(id: todo.id)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        delete(id: todo.id)
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .safeAreaInset(edge: .top, spacing: 0) {
            FilterTabBar(selection: $filter)
                .padding(.vertical, 8)
                .background(.bar)
        }
        .navigationTitle("Todo")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    // Step 8 でフォームに繋ぐ
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private func toggle(id: String) {
        guard let i = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[i].isCompleted.toggle()
    }

    private func delete(id: String) {
        todos.removeAll { $0.id == id }
    }
}

#Preview {
    NavigationStack {
        TodoListView()
    }
}
