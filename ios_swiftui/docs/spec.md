# iOS SwiftUI 実装仕様

共通仕様: `docs/spec.md` を参照。
本ファイルはiOS SwiftUI固有の技術選定・構成を記載する。

---

## 技術スタック

| レイヤー | 技術 |
|---|---|
| 状態管理 | @Observable（iOS 17+） / @Query |
| ナビゲーション | NavigationStack + sheet |
| ローカルDB | SwiftData |
| API通信 | URLSession（async/await） |
| WebView（詳細・ログイン） | WKWebView（UIViewRepresentable） |
| OAuth | ASWebAuthenticationSession |
| セキュアストレージ | Keychain（Security framework） |
| 最低iOS | 17.0 |

---

## ディレクトリ構成

```
Sources/
├── App/
│   └── TodoApp.swift            # @main, ModelContainer, 認証状態の初期ルーティング
├── Config/
│   └── AppConfig.swift          # allowedHosts, baseUrl, URLスキーム定義
├── Models/
│   └── Todo.swift               # @Model（SwiftData）
├── Network/
│   └── TodoAPIClient.swift      # URLSession async/await
├── Persistence/
│   └── KeychainStore.swift      # Keychain読み書きヘルパー
├── ViewModels/
│   ├── AuthViewModel.swift      # ログイン状態管理、OAuth起動
│   └── TodoViewModel.swift      # CRUD、API同期
└── Views/
    ├── LoginView.swift
    ├── LoginWebView.swift        # WKWebView + WKScriptMessageHandler（JS Bridge）
    ├── TodoListView.swift
    ├── TodoDetailWebView.swift   # WKWebView + NavigationDelegate（ホワイトリスト）
    └── TodoFormView.swift
```

---

## 主要実装ポイント

### 認証ルーティング（TodoApp.swift）

```swift
@main
struct TodoApp: App {
    @StateObject var authVM = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            if authVM.isLoggedIn {
                TodoListView().environmentObject(authVM)
            } else {
                LoginView().environmentObject(authVM)
            }
        }
        .modelContainer(for: Todo.self)
    }
}
```

### JS Bridge受信（LoginWebView）

```swift
// WKScriptMessageHandler
func userContentController(_ controller: WKUserContentController,
                            didReceive message: WKScriptMessage) {
    guard message.name == "authBridge",
          let body = message.body as? [String: Any],
          let token = body["token"] as? String else { return }
    authVM.login(token: token)
}
```

### WebViewホワイトリスト制御

```swift
// WKNavigationDelegate
func webView(_ webView: WKWebView,
             decidePolicyFor action: WKNavigationAction,
             decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    guard let host = action.request.url?.host,
          AppConfig.allowedHosts.contains(host) else {
        // ブロック + アラート表示
        decisionHandler(.cancel)
        return
    }
    decisionHandler(.allow)
}
```

### OAuth（ASWebAuthenticationSession）

```swift
let session = ASWebAuthenticationSession(
    url: AppConfig.oauthURL,
    callbackURLScheme: "todoapp"
) { callbackURL, error in
    guard let token = callbackURL?.queryParameters["token"] else { return }
    authVM.login(token: token)
}
session.presentationContextProvider = self
session.start()
```
