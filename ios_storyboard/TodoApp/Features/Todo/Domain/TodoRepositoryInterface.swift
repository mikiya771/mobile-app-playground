import Foundation

@MainActor
protocol TodoRepositoryInterface {
    func fetchAll() -> [Todo]
    func save(_ todo: Todo)
    func delete(id: String)
    func toggle(id: String)
    func syncFromAPI() async throws
}
