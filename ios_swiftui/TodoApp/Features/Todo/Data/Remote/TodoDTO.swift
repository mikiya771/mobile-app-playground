import Foundation

// JSONPlaceholder のレスポンス型
struct TodoDTO: Decodable, Sendable {
    let id: Int
    let title: String
    let completed: Bool

    func toDomain() -> Todo {
        Todo(
            id: "api_\(id)",
            title: title,
            description: "APIから取得",
            isCompleted: completed,
            priority: .medium
        )
    }
}
