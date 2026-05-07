# iOS SwiftUI 学習ノート（読み物）

外出先でも読める概念まとめ。手を動かす課題は `exercises.md` を参照。

---

## 進捗

- [x] Step 1: SwiftUI の View ツリーと @main エントリポイントを理解する
- [x] Step 2: @State / @Binding / @Observable の使い分けを体感する
- [x] Step 3: レイアウト（VStack / HStack / ZStack / Modifier）を触る
- [x] Step 4: モデルクラス Todo を作る（Domain Entity）
- [x] Step 5 & 6: リスト表示とインタラクション（List + swipeActions）
- [x] Step 7: SwiftData で CRUD を実装する / @Observable ViewModel + Clean Architecture
- [x] Step 8: 一覧 → 詳細WebView → 編集フォームを繋ぐ（NavigationStack）
- [x] Step 9: AuthGuard を追加する
- [x] Step 10: JSONPlaceholder から Todo を取得・同期する（URLSession）
- [ ] Step 11: UIViewRepresentable で WKWebView を表示する
- [ ] Step 12: ホワイトリスト制御を実装する（WKNavigationDelegate）
- [ ] Step 13: ログイン画面（WebView + WKScriptMessageHandler JS Bridge）
- [ ] Step 14: Keychain でトークン管理・AuthGuard
- [ ] Step 15: OAuth フロー（ASWebAuthenticationSession）

---

## アーキテクチャ方針

### View の使用ルール

| アクセス方法 | Component 層 | Screen 層 |
|---|---|---|
| `@Environment(\.colorScheme)` | ✅ 許容 | ✅ 許容 |
| `@State var viewModel` | ❌ 引数で渡す | ✅ 許容 |
| `NavigationLink` / `navigationDestination` | ❌ コールバック | ✅ 許容 |
| SwiftData `@Query` | ❌ | ✅ 許容 |
| `@Environment(\.modelContext)` | ❌ | ✅ 許容 |

**理由**: Flutter の「ウィジェット層は context を直接触らない」と同じ原則。  
Component は引数だけを受け取り、イベントを closure で上に返す。

### データフローの原則

```
ViewModel（@Observable）
  ↓ プロパティ参照（差分検知自動）
Screen View（@State var viewModel = ...）
  ↓ 引数で下に流す（prop drilling）
子 View（引数だけを見る）
  ↓ closure（コールバック）で上に返す
ViewModel（状態更新）
```

- **`@State var viewModel` は Screen 層にのみ書く**
- **子 View は引数と closure だけを受け取る**

### Flutter との対応

| Flutter / Riverpod | iOS SwiftUI |
|---|---|
| `ref.watch(todoListProvider)` | `viewModel.todos`（@Observable で自動追跡） |
| `state.copyWith(...)` | プロパティを直接更新（struct でなく class） |
| `Notifier.build()` の `_load()` | `.task { await viewModel.load() }` |
| `ProviderScope` | `@State var viewModel = TodoListViewModel(...)` |
| `ConsumerWidget` | `View`（@Observable を参照するだけで OK） |

---

## Phase 1: SwiftUI の基礎

### Step 1: View ツリーと @main エントリポイント

SwiftUI の UI はすべて **`View` プロトコルに準拠した struct の入れ子（ツリー）** で表現される。  
Flutter の Widget ツリーに相当するが、クラスではなく struct で記述する。

```swift
// Flutter の Widget ツリーに対応する SwiftUI ツリー
@main
struct TodoApp: App {           // MaterialApp に相当
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {      // Scaffold に相当
    var body: some View {
        NavigationStack {
            VStack {            // Column に相当
                Text("Hello")
            }
        }
    }
}
```

**`View` が提供するもの**

| 機能 | SwiftUI | Flutter |
|---|---|---|
| レイアウト | `VStack` / `HStack` / `ZStack` | `Column` / `Row` / `Stack` |
| テキスト | `Text` | `Text` |
| 画像 | `Image` | `Image` |
| ボタン | `Button` | `ElevatedButton` |
| リスト | `List` | `ListView` |

---

### Step 2: 状態管理（@State / @Binding / @Observable）

#### @State — ローカルな状態

```swift
// Flutter の setState に対応
struct CounterView: View {
    @State private var count = 0  // この View が所有する状態

    var body: some View {
        Button("Count: \(count)") {
            count += 1
        }
    }
}
```

#### @Binding — 親から渡された状態

```swift
// Flutter の ValueNotifier + ValueListenableBuilder に相当
struct ToggleView: View {
    @Binding var isOn: Bool  // 親が所有、子が読み書き

    var body: some View {
        Toggle("Switch", isOn: $isOn)
    }
}
```

#### @Observable — ViewModel の状態管理

```swift
// Flutter の Riverpod Notifier に対応
@Observable
final class CounterViewModel {
    var count = 0  // @Published 不要、自動で追跡

    func increment() { count += 1 }
}

struct CounterScreen: View {
    @State private var viewModel = CounterViewModel()

    var body: some View {
        Button("Count: \(viewModel.count)") {
            viewModel.increment()
        }
    }
}
```

`@Observable` は iOS 17 以降。`viewModel.count` を参照するだけで自動的に変化が追跡される。

---

## Phase 2: レイアウト

### Step 3: VStack / HStack / ZStack と Modifier

```swift
// Flutter の Column + Container に対応
VStack(alignment: .leading, spacing: 8) {
    Text("タイトル")
        .font(.headline)           // TextStyle に相当
        .foregroundStyle(.primary) // color に相当
    Text("説明")
        .font(.body)
        .lineLimit(2)              // overflow: TextOverflow.ellipsis に相当
}
.padding(16)                       // EdgeInsets に相当
.background(.white)                // decoration: BoxDecoration に相当
.cornerRadius(8)
```

**Modifier チェーンのルール**

- 上から順に適用される（Flutter と同じ）
- `padding` → `background` の順だと padding も背景色が付く
- `background` → `padding` の順だと padding は透明

---

## Phase 3: データモデル

### Step 4: Todo Domain Entity

SwiftUI では **Domain Entity**（プレーンな struct）と **SwiftData @Model**（DB レコード）を分離する。

```swift
// Domain Entity — Flutter の Todo クラスに相当（プレーンな値型）
struct Todo: Identifiable, Hashable {
    let id: String
    var title: String
    var description: String
    var isCompleted: Bool
    var priority: TodoPriority
    var createdAt: Date
}

enum TodoPriority: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"

    var label: String {
        switch self {
        case .low: "低"
        case .medium: "中"
        case .high: "高"
        }
    }

    var color: Color {
        switch self {
        case .low: .green
        case .medium: .orange
        case .high: .red
        }
    }
}
```

---

## Phase 4: リスト表示とインタラクション

### Step 5 & 6: List + swipeActions

```swift
// Flutter の ListView.builder + Dismissible に対応
List {
    ForEach(todos) { todo in
        TodoCard(todo: todo, onToggle: { viewModel.toggle(id: todo.id) })
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    viewModel.delete(id: todo.id)
                } label: {
                    Label("削除", systemImage: "trash")
                }
            }
    }
}
```

---

## Phase 5: 永続化（SwiftData）

### Step 7: SwiftData で CRUD

SwiftData は CoreData 上に構築されたモダン ORM。SQL を書かずにクラス定義だけでスキーマが決まる。

```swift
// @Model を付けると SwiftData の管理対象になる
@Model
final class TodoItem {
    @Attribute(.unique) var id: String
    var title: String
    // ...
}

// CRUD
// Create
context.insert(TodoItem(id: UUID().uuidString, title: "買い物"))

// Read（@Query マクロ）
@Query(sort: \TodoItem.createdAt) var items: [TodoItem]

// Update
item.title = "新タイトル"  // context.save() 不要（自動保存）

// Delete
context.delete(item)
```

---

## Phase 6: ナビゲーション

### Step 8: NavigationStack + NavigationPath

```swift
// go_router の GoRouter に相当する AppRouter
@Observable
final class AppRouter {
    var path = NavigationPath()
    var isLoggedIn = false

    func push(_ route: AppRoute) { path.append(route) }
    func pop() { path.removeLast() }
    func replaceRoot() { path = NavigationPath() }
}

// go_router の redirect に相当する AuthGuard
Group {
    if router.isLoggedIn {
        NavigationStack(path: $router.path) {
            TodoListView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .todoDetail(let id): TodoDetailWebView(id: id)
                    case .todoForm(let todo): TodoFormView(todo: todo)
                    }
                }
        }
    } else {
        LoginView()
    }
}
.environment(router)
```

---

## Phase 7: API 通信

### Step 10: URLSession + async/await

```swift
// Flutter の dio + Interceptor に相当
// BaseOptions(baseUrl: ...) → static let baseURL

struct TodoDTO: Decodable {
    let id: Int
    let title: String
    let completed: Bool
}

func fetchTodos() async throws -> [TodoDTO] {
    var components = URLComponents(url: baseURL.appendingPathComponent("/todos"),
                                    resolvingAgainstBaseURL: false)!
    components.queryItems = [URLQueryItem(name: "_limit", value: "20")]
    let (data, _) = try await URLSession.shared.data(from: components.url!)
    return try JSONDecoder().decode([TodoDTO].self, from: data)
}
```

---

## Phase 8: WebView

### Step 11: UIViewRepresentable で WKWebView をラップ

SwiftUI には WKWebView が存在しないため、UIKit の `UIViewRepresentable` でブリッジする。  
Flutter の `Platform.isAndroid ? AndroidView : UiKitView` の iOS 側に相当。

```swift
struct WebViewRepresentable: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.load(URLRequest(url: url))
    }
}
```

### Step 12: ホワイトリスト制御（WKNavigationDelegate）

```swift
// Flutter の NavigationDelegate.onNavigationRequest に相当
class Coordinator: NSObject, WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let host = action.request.url?.host else {
            decisionHandler(.cancel); return
        }
        if WebViewConfig.allowedHosts.contains(host) {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
            // アラート表示
        }
    }
}
```

---

## Phase 9: 認証

### Step 13: JS Bridge（WKScriptMessageHandler）

```swift
// Flutter: controller.addJavaScriptChannel('FlutterAuth', ...)
// iOS: WKUserContentController.add(_:name:)

config.userContentController.add(coordinator, name: "FlutterAuth")

// Coordinator で受信
func userContentController(_ controller: WKUserContentController,
                            didReceive message: WKScriptMessage) {
    guard message.name == "FlutterAuth",
          let body = message.body as? String,
          let data = body.data(using: .utf8),
          let json = try? JSONDecoder().decode([String: String].self, from: data),
          let token = json["token"] else { return }
    onMessage?(token)
}
```

### Step 14: Keychain でトークン管理

```swift
// flutter_secure_storage の iOS 実装と同等
// Keychain は OS レベルで AES 暗号化される
final class TokenStorage {
    func save(_ token: String) throws { ... }
    func load() throws -> String? { ... }
    func delete() throws { ... }
}
```

### Step 15: ASWebAuthenticationSession

```swift
// flutter_web_auth_2 の iOS 実装と同等
// URLScheme: todoapp://callback?token=...
let session = ASWebAuthenticationSession(
    url: authURL,
    callbackURLScheme: "todoapp"
) { url, error in
    guard let token = url?.queryParam("token") else { return }
    Task { await authViewModel.saveToken(token) }
}
session.prefersEphemeralWebBrowserSession = true
session.start()
```
