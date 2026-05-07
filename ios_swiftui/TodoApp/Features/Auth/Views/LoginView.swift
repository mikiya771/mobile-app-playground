import SwiftUI
import AuthenticationServices

// Step 15: OAuth ボタンに ASWebAuthenticationSession を実装
struct LoginView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var showWebViewLogin = false

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)
                Text("TodoApp")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }

            VStack(spacing: 12) {
                Button {
                    showWebViewLogin = true
                } label: {
                    Label("自社アカウントでログイン", systemImage: "person.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    startOAuth()
                } label: {
                    Label("OAuthでログイン", systemImage: "lock.shield")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.horizontal, 32)
        }
        .sheet(isPresented: $showWebViewLogin) {
            NavigationStack {
                LoginWebView()
            }
        }
    }

    // flutter_web_auth_2 の iOS 側実装と同等
    private func startOAuth() {
        let authURL = URL(string: "https://auth.example.com/oauth?redirect_uri=todoapp://callback")!
        let session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "todoapp"
        ) { callbackURL, error in
            guard let url = callbackURL,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let token = components.queryItems?.first(where: { $0.name == "token" })?.value
            else {
                // デモ用フォールバック: 実際の OAuth サーバーがないためモックトークンを使用
                authViewModel.login(token: "mock_oauth_token_\(Int.random(in: 1000...9999))")
                return
            }
            authViewModel.login(token: token)
        }
        session.prefersEphemeralWebBrowserSession = false

        // ASWebAuthenticationSession には presentationContextProvider が必要
        // SwiftUI では @Environment(\.openURL) か UIWindowScene を経由する
        // iOS 17 以降: シートから呼び出せばシステムが context を自動解決する
        session.start()
    }
}

#Preview {
    LoginView()
        .environment(AuthViewModel())
}
