import SwiftUI
import WebKit

// Step 13: ローカル HTML を WKWebView で表示し JS Bridge でトークンを受取る
// Flutter の LoginWebViewPage に相当
struct LoginWebView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    // login.html をバンドルリソースからロードする
    // html/login.html を TodoApp バンドルにコピーする（Step 13 で設定）
    private var loginURL: URL {
        Bundle.main.url(forResource: "login", withExtension: "html")
            ?? URL(string: "about:blank")!
    }

    var body: some View {
        WebViewRepresentable(
            url: loginURL,
            onMessage: { json in
                handleMessage(json)
            },
            allowedHosts: []   // ローカル HTML はホスト制御外
        )
        .navigationTitle("ログイン")
        .navigationBarTitleDisplayMode(.inline)
        .ignoresSafeArea(edges: .bottom)
    }

    private func handleMessage(_ json: String) {
        guard let data = json.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: String].self, from: data),
              let token = dict["token"] else { return }
        authViewModel.login(token: token)
    }
}

#Preview {
    NavigationStack {
        LoginWebView()
            .environment(AuthViewModel())
    }
}
