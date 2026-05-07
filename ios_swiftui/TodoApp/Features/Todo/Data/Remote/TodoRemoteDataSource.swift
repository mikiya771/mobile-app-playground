import Foundation

// Flutter の TodoRemoteDataSource に相当
// dio の BaseOptions(baseUrl: ...) → static let baseURL
struct TodoRemoteDataSource {
    private static let baseURL = URL(string: "https://jsonplaceholder.typicode.com")!

    func fetchTodos() async throws -> [TodoDTO] {
        var components = URLComponents(url: Self.baseURL.appendingPathComponent("/todos"),
                                       resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "_limit", value: "20")]
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        return try JSONDecoder().decode([TodoDTO].self, from: data)
    }
}
