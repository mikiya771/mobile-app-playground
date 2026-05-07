import Foundation

// Step 14: UserDefaults → Keychain に差し替え
@MainActor
final class AuthViewModel {
    static let shared = AuthViewModel()
    private(set) var isLoggedIn: Bool = false

    private init() {}

    func initialize() {
        isLoggedIn = TokenStorage.load() != nil
    }

    func login(token: String) {
        TokenStorage.save(token)
        isLoggedIn = true
    }

    func logout() {
        TokenStorage.delete()
        isLoggedIn = false
    }
}
