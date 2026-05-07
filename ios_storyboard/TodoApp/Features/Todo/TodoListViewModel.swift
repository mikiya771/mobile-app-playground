import Foundation

// UIKit では @Observable 非対応のため onUpdate クロージャで通知
@MainActor
final class TodoListViewModel {
    private let repository: TodoRepositoryInterface
    var onUpdate: (() -> Void)?

    private(set) var todos: [Todo] = []
    var filter: TodoFilter = .all {
        didSet { onUpdate?() }
    }

    var filteredTodos: [Todo] {
        switch filter {
        case .all: todos
        case .active: todos.filter { !$0.isCompleted }
        case .completed: todos.filter { $0.isCompleted }
        }
    }

    init(repository: TodoRepositoryInterface = TodoRepository()) {
        self.repository = repository
    }

    func loadTodos() {
        todos = repository.fetchAll()
        onUpdate?()
    }

    func toggle(id: String) {
        repository.toggle(id: id)
        loadTodos()
    }

    func delete(id: String) {
        repository.delete(id: id)
        loadTodos()
    }

    func save(_ todo: Todo) {
        repository.save(todo)
        loadTodos()
    }

    func syncFromAPI() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            try? await self.repository.syncFromAPI()
            self.loadTodos()
        }
    }
}
