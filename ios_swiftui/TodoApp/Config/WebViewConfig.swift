import Foundation

// Flutter の WebViewConfig / AppConfig.allowedHosts に相当
enum WebViewConfig {
    static let allowedHosts: Set<String> = [
        "jsonplaceholder.typicode.com",   // 詳細ページ用（デモ）
        "auth.example.com",               // ログイン用（デモはローカルHTML）
    ]

    static func isAllowed(_ host: String) -> Bool {
        allowedHosts.contains(host)
    }
}
