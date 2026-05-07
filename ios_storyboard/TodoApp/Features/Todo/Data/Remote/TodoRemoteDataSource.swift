import Foundation

// Flutter の TodoRemoteDataSource に相当
struct TodoRemoteDataSource {
    private let baseURL = "https://jsonplaceholder.typicode.com"

    func fetchTodos() async throws -> [Todo] {
        guard let url = URL(string: "\(baseURL)/todos?_limit=10") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        let items = try JSONDecoder().decode([RemoteTodo].self, from: data)
        return items.map { $0.toDomain() }
    }
}

private struct RemoteTodo: Decodable {
    let id: Int
    let title: String
    let completed: Bool

    func toDomain() -> Todo {
        Todo(
            id: String(id),
            title: title,
            isCompleted: completed,
            priority: .medium
        )
    }
}
