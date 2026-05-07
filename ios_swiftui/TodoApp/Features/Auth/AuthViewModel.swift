import Foundation

// Flutter の AuthProvider + TokenStorage に相当
@Observable
@MainActor
final class AuthViewModel {
    var isLoggedIn = false
    var token: String? = nil

    // 起動時に Keychain からトークンを読み込む
    func initialize() {
        do {
            if let saved = try TokenStorage.load() {
                token = saved
                isLoggedIn = true
            }
        } catch {
            // Keychain 読み込み失敗はログアウト扱い
            isLoggedIn = false
        }
    }

    func login(token: String) {
        do {
            try TokenStorage.save(token)
            self.token = token
            self.isLoggedIn = true
        } catch {
            // 保存失敗時でもインメモリでログイン状態を維持
            self.token = token
            self.isLoggedIn = true
        }
    }

    func logout() {
        try? TokenStorage.delete()
        token = nil
        isLoggedIn = false
    }
}
