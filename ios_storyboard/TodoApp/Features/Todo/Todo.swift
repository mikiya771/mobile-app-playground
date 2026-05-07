import Foundation

struct Todo: Identifiable, Hashable, Sendable {
    let id: String
    var title: String
    var description: String
    var isCompleted: Bool
    var priority: TodoPriority
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        title: String,
        description: String = "",
        isCompleted: Bool = false,
        priority: TodoPriority = .medium,
        createdAt: Date = .now
    ) {
        self.id = id; self.title = title; self.description = description
        self.isCompleted = isCompleted; self.priority = priority; self.createdAt = createdAt
    }
}

enum TodoPriority: String, CaseIterable, Sendable {
    case low = "low", medium = "medium", high = "high"

    var label: String {
        switch self { case .low: "低"; case .medium: "中"; case .high: "高" }
    }
}

enum TodoFilter: String, CaseIterable {
    case all = "すべて", active = "未完了", completed = "完了"
}

extension Todo {
    static let samples: [Todo] = [
        Todo(id: "1", title: "牛乳を買う", description: "近くのスーパーで", priority: .medium),
        Todo(id: "2", title: "コードレビュー", description: "PRを確認する", isCompleted: true, priority: .high),
        Todo(id: "3", title: "ランニング", description: "30分", priority: .low),
    ]
}
