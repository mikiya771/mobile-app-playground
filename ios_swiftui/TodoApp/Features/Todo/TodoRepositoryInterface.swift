import Foundation

// Domain Layer — Repository Interface（protocol）
// Flutter の TodoRepositoryInterface に相当
@MainActor
protocol TodoRepositoryInterface {
    func load() async throws -> [Todo]
    func save(_ todo: Todo) async throws
    func update(_ todo: Todo) async throws
    func delete(id: String) async throws
    func sync() async throws -> [Todo]
}
