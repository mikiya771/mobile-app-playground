import Foundation

// UIKit + @MainActor。Keychain は Step 14 で差し替え
@MainActor
final class AuthViewModel {
    static let shared = AuthViewModel()

    private let key = "auth_token"
    private(set) var isLoggedIn: Bool = false

    private init() {}

    func initialize() {
        // Step 14 で Keychain に置き換え。現時点は UserDefaults で代替
        isLoggedIn = UserDefaults.standard.string(forKey: key) != nil
    }

    func login(token: String) {
        UserDefaults.standard.set(token, forKey: key)
        isLoggedIn = true
    }

    func logout() {
        UserDefaults.standard.removeObject(forKey: key)
        isLoggedIn = false
    }
}
