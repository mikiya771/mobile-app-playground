import SwiftUI

// Step 13: 2ボタン構成のログイン画面
// 「自社アカウント」→ LoginWebView（WKWebView + JS Bridge）
// 「OAuth」→ Step 15 で ASWebAuthenticationSession に置き換え
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
                    // Step 15 で ASWebAuthenticationSession に置き換え
                    authViewModel.login(token: "mock_oauth_token")
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
}

#Preview {
    LoginView()
        .environment(AuthViewModel())
}
