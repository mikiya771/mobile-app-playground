# iOS SwiftUI 個別仕様

共通仕様は `docs/spec.md`（ルート）を参照。ここには iOS SwiftUI 固有の技術選定を記載する。

---

## 採用技術スタック

| 役割 | 技術 |
|------|------|
| 言語 | Swift 6 |
| UI | SwiftUI |
| ナビゲーション | NavigationStack + NavigationPath |
| 状態管理 | @Observable（Observation framework） |
| DI | 手動 DI（イニシャライザ注入） |
| 永続化 | SwiftData（iOS 17+） |
| HTTP クライアント | URLSession（標準ライブラリ） |
| WebView | WKWebView（UIViewRepresentable） |
| セキュアストレージ | Keychain Services（Security framework） |
| OAuth | ASWebAuthenticationSession |

> **@Observable について**: iOS 17 から導入された Observation framework。従来の `ObservableObject` + `@Published` より宣言がシンプルで、必要なプロパティだけ再描画が走る。

---

## Flutter との技術対応表

| Flutter | iOS SwiftUI |
|---------|-------------|
| `StatelessWidget` | `View`（struct） |
| `StatefulWidget` + `setState` | `@State` / `@Binding` |
| `Riverpod Notifier` | `@Observable` ViewModel |
| `ref.watch(provider)` | `@State var vm = ViewModel()` + `@Bindable` |
| `Column` / `Row` / `Container` | `VStack` / `HStack` / `ZStack` |
| `go_router` | `NavigationStack` + `NavigationPath` |
| `sqflite` | SwiftData |
| `dio` | `URLSession` + `async/await` |
| `webview_flutter` | `UIViewRepresentable<WKWebView>` |
| `flutter_secure_storage` | Keychain Services |
| `flutter_web_auth_2` | `ASWebAuthenticationSession` |

---

## アーキテクチャ方針

### Clean Architecture の3層

```
Presentation Layer  View（SwiftUI）/ ViewModel（@Observable）
Domain Layer        Entity（Todo）/ Repository Interface
Data Layer          Repository 実装（SwiftData + URLSession）
```

依存の向きは **外 → 内**。View は ViewModel を知るが ViewModel は View を知らない。

### データフローの原則

```
ViewModel（@Observable）
  ↓ プロパティ参照（自動で差分検知）
View（状態を受け取って描画）
  ↓ アクション（async メソッド呼び出し）
ViewModel（状態を更新）
```

SwiftUI は `@Observable` オブジェクトの変化したプロパティだけを差分検知する。Flutter の Riverpod `select` に似た効率的な再描画が自動で行われる。

### ViewModel の定義

```swift
// Flutter 版（対応）
// class TodoListNotifier extends Notifier<TodoListState>

@Observable
final class TodoListViewModel {
    var todos: [Todo] = []
    var filter: TodoFilter = .all
    var isLoading: Bool = true
    var errorMessage: String? = nil

    private let repository: TodoRepositoryInterface

    init(repository: TodoRepositoryInterface) {
        self.repository = repository
    }

    func load() async { ... }
    func toggle(id: String) async { ... }
}
```

View 側は `@State var viewModel = TodoListViewModel(...)` で保持し、`@Bindable var viewModel` で双方向バインディングを使う。

---

## ディレクトリ構成

```
ios_swiftui/TodoApp/
  App/
    TodoApp.swift               ← @main エントリポイント
  Config/
    WebViewConfig.swift         ← ホワイトリスト定数
  Features/
    Auth/
      AuthViewModel.swift
      TokenStorage.swift        ← Keychain ラッパー
      Views/
        LoginView.swift         ← ログイン画面（2ボタン）
        LoginWebView.swift      ← WKWebView + JS Bridge
    Todo/
      Todo.swift                ← Domain Entity（@Model なし）
      TodoRepositoryInterface.swift
      TodoRepository.swift
      TodoListViewModel.swift
      TodoDetailViewModel.swift
      TodoFormViewModel.swift
      Data/
        Local/
          TodoLocalDataSource.swift
          TodoItem.swift        ← SwiftData @Model（DBレコード型）
        Remote/
          TodoRemoteDataSource.swift
          TodoDTO.swift
      Views/
        TodoListView.swift
        TodoDetailWebView.swift ← WebView で詳細表示
        TodoFormView.swift
      Components/
        FilterTabBar.swift
        PriorityBadge.swift
        TodoCard.swift
    WebView/
      WebViewRepresentable.swift ← UIViewRepresentable
  Navigation/
    AppRouter.swift             ← NavigationPath 管理（router.dart 相当）
    AppRoute.swift              ← ルート enum
```

---

## ナビゲーション（NavigationStack）

### ルート定義

```swift
// go_router との対応
// GoRoute(path: '/todos/:id') → .todoDetail(id: String)
enum AppRoute: Hashable {
    case todoDetail(id: String)
    case todoForm(todo: Todo?)   // nil = 新規
}

NavigationStack(path: $router.path) {
    TodoListView()
        .navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .todoDetail(let id): TodoDetailWebView(id: id)
            case .todoForm(let todo): TodoFormView(todo: todo)
            }
        }
}
```

### ルート置換（ログイン ↔ 一覧）

`@Observable AppRouter` がグローバルに `isLoggedIn` を保持し、`Group` で分岐する。

```swift
// go_router の redirect に相当
Group {
    if router.isLoggedIn {
        NavigationStack(path: $router.path) { TodoListView() ... }
    } else {
        LoginView()
    }
}
```

---

## WebView（UIViewRepresentable）

Flutter の `webview_flutter` に相当する。SwiftUI には WebView が存在しないため UIKit の `WKWebView` をラップして使う。

```swift
struct WebViewRepresentable: UIViewRepresentable {
    let url: URL
    let onMessage: ((String) -> Void)?  // JS Bridge コールバック

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // JS Bridge 登録
        config.userContentController.add(context.coordinator, name: "FlutterAuth")
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.load(URLRequest(url: url))
    }
}
```

---

## JS Bridge（WKScriptMessageHandler）

Flutter の `JavaScriptChannel` に相当する仕組み。

```swift
// Flutter: controller.addJavaScriptChannel('FlutterAuth', ...)
// iOS:
class Coordinator: NSObject, WKScriptMessageHandler {
    func userContentController(
        _ controller: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == "FlutterAuth",
              let body = message.body as? String else { return }
        onMessage?(body)
    }
}
```

HTML 側の呼び出しは Flutter 版と同一:
```javascript
window.FlutterAuth.postMessage(JSON.stringify({ token: "mock_token" }))
```

---

## セキュアストレージ（Keychain）

```swift
// flutter_secure_storage の iOS バックエンドの実装と同等
func save(key: String, value: String) throws {
    let data = value.data(using: .utf8)!
    let query: [CFString: Any] = [
        kSecClass: kSecClassGenericPassword,
        kSecAttrAccount: key,
        kSecValueData: data,
    ]
    SecItemDelete(query as CFDictionary)
    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else { throw KeychainError.saveFailed(status) }
}
```

Android の `EncryptedSharedPreferences` に相当。iOS は Keychain が OS レベルで暗号化を保証する。

---

## OAuth（ASWebAuthenticationSession）

```swift
// flutter_web_auth_2 の iOS バックエンドの実装と同等
let session = ASWebAuthenticationSession(
    url: URL(string: authUrl)!,
    callbackURLScheme: "todoapp"
) { callbackURL, error in
    guard let url = callbackURL,
          let token = URLComponents(url: url, resolvingAgainstBaseURL: false)?
              .queryItems?.first(where: { $0.name == "token" })?.value
    else { return }
    Task { await authViewModel.saveToken(token) }
}
session.presentationContextProvider = self
session.start()
```

Android の Chrome Custom Tabs に相当。

---

## SwiftData スキーマ

共通仕様の SQLite スキーマを SwiftData Model で表現する。

```swift
// Flutter: sqflite の INSERT 文に相当するが、SwiftData は ORM なのでスキーマ定義が不要
@Model
final class TodoItem {
    @Attribute(.unique) var id: String
    var title: String
    var desc: String       // description は Swift キーワードと衝突するため desc に
    var isCompleted: Bool
    var priority: String   // "low" | "medium" | "high"
    var createdAt: Date

    init(id: String, title: String, desc: String = "",
         isCompleted: Bool = false, priority: String = "medium", createdAt: Date = .now) {
        self.id = id; self.title = title; self.desc = desc
        self.isCompleted = isCompleted; self.priority = priority; self.createdAt = createdAt
    }
}
```

Domain の `Todo` struct（プレーンな値型）と `TodoItem`（@Model）は別クラス。Repository がマッピングを担う。

---

## URLSession 設定

```swift
// dio の BaseOptions(baseUrl: ...) に相当
struct TodoAPI {
    static let baseURL = URL(string: "https://jsonplaceholder.typicode.com")!

    static func fetch() async throws -> [TodoDTO] {
        var components = URLComponents(url: baseURL.appendingPathComponent("/todos"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "_limit", value: "20")]
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        return try JSONDecoder().decode([TodoDTO].self, from: data)
    }
}
```
