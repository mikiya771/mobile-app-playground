import Foundation
import SwiftData

// Data Layer — Repository 実装
// Flutter の TodoRepository に相当
@MainActor
final class TodoRepository: TodoRepositoryInterface {
    private let local: TodoLocalDataSource
    private let remote: TodoRemoteDataSource

    init(context: ModelContext) {
        self.local = TodoLocalDataSource(context: context)
        self.remote = TodoRemoteDataSource()
    }

    func load() async throws -> [Todo] {
        try local.fetchAll()
    }

    func save(_ todo: Todo) async throws {
        try local.insert(todo)
    }

    func update(_ todo: Todo) async throws {
        try local.update(todo)
    }

    func delete(id: String) async throws {
        try local.delete(id: id)
    }

    func sync() async throws -> [Todo] {
        let dtos = try await remote.fetchTodos()
        var added: [Todo] = []
        for dto in dtos {
            let todo = dto.toDomain()
            if !(try local.exists(id: todo.id)) {
                try local.insert(todo)
                added.append(todo)
            }
        }
        return added
    }
}
