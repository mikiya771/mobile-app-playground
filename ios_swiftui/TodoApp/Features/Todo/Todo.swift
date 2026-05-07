import Foundation

// Domain Entity — プレーンな値型（SwiftData @Model とは別物）
// Flutter の todo.dart の Todo クラスに相当
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
        self.id = id
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
        self.priority = priority
        self.createdAt = createdAt
    }
}

enum TodoPriority: String, CaseIterable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"

    var label: String {
        switch self {
        case .low: "低"
        case .medium: "中"
        case .high: "高"
        }
    }
}

enum TodoFilter: String, CaseIterable {
    case all = "すべて"
    case active = "未完了"
    case completed = "完了"
}

// ダミーデータ（Step 5 以降のリスト表示で使用）
extension Todo {
    static let samples: [Todo] = [
        Todo(id: "1", title: "牛乳を買う", description: "近くのスーパーで", isCompleted: false, priority: .medium),
        Todo(id: "2", title: "コードレビュー", description: "PRを確認する", isCompleted: true, priority: .high),
        Todo(id: "3", title: "ランニング", description: "30分", isCompleted: false, priority: .low),
        Todo(id: "4", title: "読書", description: "SwiftUI入門", isCompleted: false, priority: .medium),
        Todo(id: "5", title: "請求書確認", description: "", isCompleted: true, priority: .high),
    ]
}
