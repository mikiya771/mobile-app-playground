import Foundation

// Flutter の TodoListNotifier に相当
@Observable
@MainActor
final class TodoListViewModel {
    var todos: [Todo] = []
    var filter: TodoFilter = .all
    var isLoading = true
    var errorMessage: String? = nil
    var isSyncing = false

    private let repository: TodoRepositoryInterface

    init(repository: TodoRepositoryInterface) {
        self.repository = repository
    }

    var filteredTodos: [Todo] {
        switch filter {
        case .all: todos
        case .active: todos.filter { !$0.isCompleted }
        case .completed: todos.filter { $0.isCompleted }
        }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            todos = try await repository.load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggle(id: String) async {
        guard let i = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[i].isCompleted.toggle()
        do {
            try await repository.update(todos[i])
        } catch {
            todos[i].isCompleted.toggle()
            errorMessage = error.localizedDescription
        }
    }

    func delete(id: String) async {
        todos.removeAll { $0.id == id }
        do {
            try await repository.delete(id: id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveTodo(_ todo: Todo) async {
        if todos.contains(where: { $0.id == todo.id }) {
            todos.removeAll { $0.id == todo.id }
            todos.insert(todo, at: 0)
            do { try await repository.update(todo) }
            catch { errorMessage = error.localizedDescription }
        } else {
            todos.insert(todo, at: 0)
            do { try await repository.save(todo) }
            catch { errorMessage = error.localizedDescription }
        }
    }

    func syncFromAPI() async {
        isSyncing = true
        defer { isSyncing = false }
        do {
            let added = try await repository.sync()
            todos.append(contentsOf: added)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
