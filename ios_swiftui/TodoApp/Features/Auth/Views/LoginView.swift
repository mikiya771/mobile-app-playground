import SwiftUI

// Step 9: ログインボタン2つのダミー画面
// Step 13 で WebView + JS Bridge に置き換わる
struct LoginView: View {
    @Environment(AuthViewModel.self) private var authViewModel

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
                    // Step 13 で WebView ログインに置き換え
                    authViewModel.login(token: "mock_token")
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
    }
}

#Preview {
    LoginView()
        .environment(AuthViewModel())
}
