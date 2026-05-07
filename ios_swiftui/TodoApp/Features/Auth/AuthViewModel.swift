import Foundation

// Flutter の AuthProvider に相当
@Observable
@MainActor
final class AuthViewModel {
    var isLoggedIn = false
    var token: String? = nil

    func login(token: String) {
        self.token = token
        self.isLoggedIn = true
    }

    func logout() {
        self.token = nil
        self.isLoggedIn = false
    }
}
