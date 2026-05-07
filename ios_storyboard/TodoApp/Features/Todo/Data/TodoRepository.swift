import Foundation

@MainActor
final class TodoRepository: TodoRepositoryInterface {
    private let local: TodoLocalDataSource

    init(local: TodoLocalDataSource = TodoLocalDataSource()) {
        self.local = local
    }

    func fetchAll() -> [Todo] { local.fetchAll() }

    func save(_ todo: Todo) { local.save(todo) }

    func delete(id: String) { local.delete(id: id) }

    func toggle(id: String) {
        var todos = local.fetchAll()
        guard let i = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[i].isCompleted.toggle()
        local.save(todos[i])
    }
}
