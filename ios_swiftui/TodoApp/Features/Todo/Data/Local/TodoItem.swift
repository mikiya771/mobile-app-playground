import Foundation
import SwiftData

// SwiftData @Model — DB レコード型（Room の TodoEntity 相当）
// Domain の Todo struct とは別物。Repository がマッピングを担う。
@Model
final class TodoItem {
    @Attribute(.unique) var id: String
    var title: String
    var desc: String       // description は Swift キーワードと衝突するため desc
    var isCompleted: Bool
    var priority: String   // "low" | "medium" | "high"
    var createdAt: Date

    init(id: String, title: String, desc: String = "",
         isCompleted: Bool = false, priority: String = "medium", createdAt: Date = .now) {
        self.id = id
        self.title = title
        self.desc = desc
        self.isCompleted = isCompleted
        self.priority = priority
        self.createdAt = createdAt
    }

    func toDomain() -> Todo {
        Todo(
            id: id,
            title: title,
            description: desc,
            isCompleted: isCompleted,
            priority: TodoPriority(rawValue: priority) ?? .medium,
            createdAt: createdAt
        )
    }
}

extension Todo {
    func toItem() -> TodoItem {
        TodoItem(id: id, title: title, desc: description,
                 isCompleted: isCompleted, priority: priority.rawValue, createdAt: createdAt)
    }
}
