import CoreData

// NSManagedObject ↔ Domain Todo のマッピング
// SwiftUI 版の TodoItem.toDomain() に相当
extension TodoEntity {
    func toDomain() -> Todo {
        Todo(
            id: id ?? UUID().uuidString,
            title: title ?? "",
            description: desc ?? "",
            isCompleted: isCompleted,
            priority: TodoPriority(rawValue: priority ?? "medium") ?? .medium,
            createdAt: createdAt ?? .now
        )
    }

    static func from(_ todo: Todo, in context: NSManagedObjectContext) -> TodoEntity {
        let entity = TodoEntity(context: context)
        entity.id = todo.id
        entity.title = todo.title
        entity.desc = todo.description
        entity.isCompleted = todo.isCompleted
        entity.priority = todo.priority.rawValue
        entity.createdAt = todo.createdAt
        return entity
    }

    func update(from todo: Todo) {
        title = todo.title
        desc = todo.description
        isCompleted = todo.isCompleted
        priority = todo.priority.rawValue
    }
}
