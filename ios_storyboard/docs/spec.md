# iOS Storyboard 個別仕様

共通仕様は `docs/spec.md`（ルート）を参照。ここには iOS UIKit + Storyboard 固有の技術選定を記載する。

---

## 採用技術スタック

| 役割 | 技術 |
|------|------|
| 言語 | Swift 6 |
| UI | UIKit + Storyboard（Interface Builder） |
| ナビゲーション | UINavigationController + Segue |
| 状態管理 | MVC（ViewController が状態を保持）|
| DI | 手動 DI（`prepare(for:sender:)` でインジェクション） |
| 永続化 | CoreData（NSPersistentContainer） |
| HTTP クライアント | URLSession（標準ライブラリ） |
| WebView | WKWebView（コードで追加） |
| セキュアストレージ | Keychain Services（Security framework） |
| OAuth | ASWebAuthenticationSession |

> **CoreData について**: SwiftData の前身。iOS 3 から存在する成熟した ORM。NSPersistentContainer + NSFetchedResultsController でリスト自動更新を実装する。SwiftUI の `@Query` に相当するのが `NSFetchedResultsController`。

---

## SwiftUI / Flutter との技術対応表

| Flutter | SwiftUI | iOS Storyboard |
|---------|---------|----------------|
| `Widget` / `build()` | `View` struct | `UIViewController` + Storyboard |
| `StatefulWidget` + `setState` | `@State` | `@IBOutlet` + `tableView.reloadData()` |
| `Riverpod Notifier` | `@Observable` ViewModel | ViewModel class（プレーンな Swift class） |
| `Column` / `Row` | `VStack` / `HStack` | `UIStackView` + AutoLayout |
| `ListView.builder` | `List { ForEach }` | `UITableView` + `UITableViewDataSource` |
| `go_router` | `NavigationStack` | `UINavigationController` + Segue / `present()` |
| `sqflite` | SwiftData | CoreData（NSPersistentContainer） |
| `dio` | `URLSession` + async/await | `URLSession` + async/await |
| `webview_flutter` | `UIViewRepresentable<WKWebView>` | `WKWebView`（コードで直接追加） |
| `flutter_secure_storage` | Keychain Services | Keychain Services（同一） |
| `flutter_web_auth_2` | `ASWebAuthenticationSession` | `ASWebAuthenticationSession`（同一） |

---

## アーキテクチャ方針

### MVC の3層

```
View Layer       Storyboard（XIB相当） / UIView のサブクラス
Controller Layer UIViewController（状態保持・ユーザー操作ハンドリング）
Model Layer      Entity（Todo）/ Repository / CoreData
```

SwiftUI + @Observable に比べて「Controller がビジー」になりやすいため、  
**ViewModel を Controller の外に出す MVVM 寄りの構成**を採用する。

```
ViewController
  ├── @IBOutlet → 表示の更新
  ├── @IBAction → ユーザー操作 → ViewModel のメソッド呼び出し
  └── ViewModel（状態保持・非同期処理）
        └── Repository（データ層）
```

### データフローの原則

```
ViewModel（状態を保持）
  ↓ クロージャ or delegate でコールバック
ViewController（UIをリフレッシュ）
  ↓ IBAction / タップジェスチャー
ViewModel（状態を更新）
```

Flutter の `ref.watch` に相当する「自動追跡」がないため、ViewModel の変化を  
`onUpdate: () -> Void` クロージャで ViewController に通知する。

### Flutter との対応

| Flutter / Riverpod | iOS Storyboard |
|---|---|
| `ref.watch(todoListProvider)` | `viewModel.onUpdate = { [weak self] in self?.tableView.reloadData() }` |
| `state.copyWith(...)` | ViewModel のプロパティを直接更新 |
| `Notifier.build()` の `_load()` | `viewDidLoad` で `Task { await viewModel.load() }` |
| `ProviderScope` | `prepare(for:sender:)` で ViewModel を渡す |

---

## ディレクトリ構成

```
ios_storyboard/TodoApp/
  AppDelegate.swift
  SceneDelegate.swift
  Config/
    WebViewConfig.swift
  Features/
    Auth/
      AuthViewModel.swift
      TokenStorage.swift
      LoginViewController.swift     ← Storyboard ID: LoginVC
      LoginWebViewController.swift  ← WKWebView + JS Bridge
    Todo/
      Todo.swift                    ← Domain Entity
      TodoRepositoryInterface.swift
      TodoRepository.swift
      TodoListViewModel.swift
      Data/
        Local/
          TodoLocalDataSource.swift
          TodoEntity+Extensions.swift   ← NSManagedObject extension
        Remote/
          TodoRemoteDataSource.swift
          TodoDTO.swift
      ViewControllers/
        TodoListViewController.swift  ← UITableView + NSFetchedResultsController
        TodoDetailViewController.swift ← WKWebView 詳細
        TodoFormViewController.swift  ← UITextField / UITextView / UISegmentedControl
      Views/
        TodoTableViewCell.swift
        PriorityBadgeView.swift
  Navigation/
    AuthRouter.swift               ← ログイン ↔ 一覧の画面切り替え
  Resources/
    login.html
  Storyboard/
    Main.storyboard
    LaunchScreen.storyboard
  CoreData/
    TodoApp.xcdatamodeld
  Info.plist
```

---

## ナビゲーション（Segue + UINavigationController）

### Segue 定義

```
LoginViewController
  ↓ performSegue("showTodoList") ← 認証後にルート置換
TodoListViewController（UINavigationController のルート）
  ├── performSegue("showDetail", sender: indexPath) → TodoDetailViewController
  │     ↓ performSegue("showForm", sender: todo)   → TodoFormViewController（Push）
  └── performSegue("showForm", sender: nil)         → TodoFormViewController（Modal）
```

### AuthGuard（画面切り替え）

go_router の `redirect` に相当する仕組みを `SceneDelegate.windowScene` の rootViewController 切り替えで実装する。

```swift
// ログイン後：UINavigationController をルートに設定
func showTodoList() {
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let nav = storyboard.instantiateViewController(withIdentifier: "MainNav")
    window?.rootViewController = nav
}

// ログアウト後：LoginViewController に戻す
func showLogin() {
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC")
    window?.rootViewController = loginVC
}
```

---

## WebView（WKWebView）

Storyboard には WKWebView ウィジェットが使えないため（Interface Builder 上の制限）、コードで追加する。

```swift
// UIViewController の viewDidLoad で WKWebView を追加
override func viewDidLoad() {
    super.viewDidLoad()
    let config = WKWebViewConfiguration()
    config.userContentController.add(self, name: "FlutterAuth")
    let webView = WKWebView(frame: view.bounds, configuration: config)
    webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(webView)
    webView.navigationDelegate = self
    self.webView = webView
}
```

---

## CoreData スキーマ

共通仕様の SQLite スキーマを CoreData エンティティで表現する。

```
Entity: TodoEntity
  id          String   (unique, indexed)
  title       String
  desc        String
  isCompleted Bool
  priority    String   ("low" | "medium" | "high")
  createdAt   Date
```

Domain の `Todo` struct と `TodoEntity`（NSManagedObject）は別クラス。Repository がマッピングを担う。

---

## URLSession 設定

SwiftUI 版と同一。`async/await` で記述し、`Task { }` でメインスレッドに戻す。

---

## セキュアストレージ（Keychain）

SwiftUI 版と同一の `TokenStorage` enum を使い回す。

---

## OAuth（ASWebAuthenticationSession）

SwiftUI 版と同一。`LoginViewController` が `ASWebAuthenticationPresentationContextProviding` に準拠して `presentationAnchor` を返す。
