import Foundation
import SwiftData

// SwiftData ModelContext を使った CRUD
// Flutter の TodoLocalDataSource + sqflite に相当
@MainActor
struct TodoLocalDataSource {
    let context: ModelContext

    func fetchAll() throws -> [Todo] {
        let items = try context.fetch(FetchDescriptor<TodoItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        ))
        return items.map { $0.toDomain() }
    }

    func insert(_ todo: Todo) throws {
        context.insert(todo.toItem())
    }

    func update(_ todo: Todo) throws {
        let id = todo.id
        let items = try context.fetch(FetchDescriptor<TodoItem>())
        guard let item = items.first(where: { $0.id == id }) else { return }
        item.title = todo.title
        item.desc = todo.description
        item.isCompleted = todo.isCompleted
        item.priority = todo.priority.rawValue
    }

    func delete(id: String) throws {
        let items = try context.fetch(FetchDescriptor<TodoItem>())
        if let item = items.first(where: { $0.id == id }) {
            context.delete(item)
        }
    }

    func exists(id: String) throws -> Bool {
        let items = try context.fetch(FetchDescriptor<TodoItem>())
        return items.contains { $0.id == id }
    }
}
