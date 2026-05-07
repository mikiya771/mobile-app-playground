# iOS Storyboard 学習ノート（読み物）

外出先でも読める概念まとめ。手を動かす課題は `exercises.md` を参照。

---

## 進捗

- [ ] Step 1: AppDelegate + SceneDelegate + UIViewController の起動フローを理解する
- [ ] Step 2: IBOutlet / IBAction / UILabel / UIButton の MVC を体感する
- [ ] Step 3: AutoLayout + UIStackView でレイアウトを組む
- [ ] Step 4: モデルクラス Todo を作る（Domain Entity）
- [ ] Step 5 & 6: UITableView で一覧表示 + スワイプ削除 + チェックトグル
- [ ] Step 7: CoreData CRUD + ViewModel + Clean Architecture
- [ ] Step 8: UINavigationController + Segue でマルチ画面を繋ぐ
- [ ] Step 9: AuthGuard（rootViewController 切り替え）
- [ ] Step 10: URLSession で API 同期（async/await）
- [ ] Step 11: WKWebView をコードで追加して詳細ページを表示する
- [ ] Step 12: WKNavigationDelegate でホワイトリスト制御
- [ ] Step 13: ログイン画面（WKWebView + WKScriptMessageHandler JS Bridge）
- [ ] Step 14: Keychain でトークン管理 + 起動時自動ログイン
- [ ] Step 15: OAuth フロー（ASWebAuthenticationSession）

---

## アーキテクチャ方針

### ViewController の役割

| 責務 | 担当 |
|------|------|
| IBOutlet 接続・UI更新 | ViewController |
| IBAction → ViewModel呼び出し | ViewController |
| 状態保持・非同期処理 | ViewModel |
| データ永続化・API通信 | Repository |
| データ変化の通知 | ViewModel の `onUpdate: () -> Void` クロージャ |

### Flutter / SwiftUI との対応

| Flutter / Riverpod | SwiftUI | iOS Storyboard |
|---|---|---|
| `ref.watch(...)` | `viewModel.todos`（自動追跡） | `onUpdate = { tableView.reloadData() }` |
| `Notifier.build()` の `_load()` | `.task { await vm.load() }` | `viewDidLoad` で `Task { await vm.load() }` |
| `ProviderScope` | `@State var vm = ViewModel()` | `prepare(for:sender:)` で渡す |

---

## Phase 1: UIKit の起動フロー

### Step 1: AppDelegate + SceneDelegate + UIViewController

iOS 13 以降のアプリ起動フロー:

```
UIApplicationMain（@main）
  ↓
AppDelegate.application(_:didFinishLaunchingWithOptions:)
  ↓
SceneDelegate.scene(_:willConnectTo:options:)
  ↓ window.rootViewController を設定
UINavigationController → LoginViewController（初期画面）
```

**Flutter との対応**

| Flutter | iOS Storyboard |
|---------|----------------|
| `main.dart` の `runApp(MyApp())` | `AppDelegate.application(...)` → `SceneDelegate.scene(...)` |
| `MaterialApp(home: ...)` | `window.rootViewController = ...` |
| `runApp` の起動 | `UIApplicationMain` マクロ（`@main`） |

---

## Phase 2: MVC の基礎

### Step 2: IBOutlet / IBAction

Interface Builder で UI を作り、コードと接続する仕組み。

```swift
class LoginViewController: UIViewController {
    // Interface Builder からの接続
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!

    // ボタンタップのアクション
    @IBAction func loginTapped(_ sender: UIButton) {
        // Flutter の ElevatedButton(onPressed: ...) に相当
    }
}
```

**SwiftUI との対応**

| SwiftUI | Storyboard |
|---------|------------|
| `@State var text = ""` | `@IBOutlet weak var label: UILabel!` |
| `Button { action }` | `@IBAction func buttonTapped()` |
| `Text(viewModel.count)` | `label.text = "\(viewModel.count)"` |

---

## Phase 3: AutoLayout

### Step 3: UIStackView + Constraints

AutoLayout は SwiftUI の Modifier チェーンに相当する制約ベースのレイアウトシステム。

```swift
// コードで AutoLayout を設定する例（Storyboard の代替）
button.translatesAutoresizingMaskIntoConstraints = false
NSLayoutConstraint.activate([
    button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
    button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
    button.heightAnchor.constraint(equalToConstant: 50),
    button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
])
```

**SwiftUI との対応**

| SwiftUI | Storyboard / AutoLayout |
|---------|-------------------------|
| `VStack(spacing: 8)` | `UIStackView(axis: .vertical, spacing: 8)` |
| `HStack` | `UIStackView(axis: .horizontal)` |
| `.padding(16)` | `leadingAnchor + 16`, `trailingAnchor - 16` |
| `.frame(maxWidth: .infinity)` | `leading` + `trailing` を `superview` に制約 |

---

## Phase 4: データモデル

### Step 4: Todo Domain Entity

SwiftUI 版と同一の `Todo` struct + `TodoPriority` enum を使い回す。  
CoreData Entity（`TodoEntity`）は別クラスで Repository がマッピングする。

---

## Phase 5: UITableView

### Step 5 & 6: UITableViewDataSource + UITableViewDelegate

```swift
// Flutter の ListView.builder に相当
class TodoListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
    }
}

extension TodoListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.filteredTodos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodoCell", for: indexPath) as! TodoTableViewCell
        cell.configure(with: viewModel.filteredTodos[indexPath.row])
        return cell
    }
}

// スワイプ削除（Flutter の Dismissible に相当）
extension TodoListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
        -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "削除") { [weak self] _, _, completion in
            Task { await self?.viewModel.delete(id: ...) }
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
}
```

---

## Phase 6: 永続化（CoreData）

### Step 7: NSPersistentContainer + NSFetchedResultsController

```swift
// NSPersistentContainer の初期化（AppDelegate または シングルトン）
lazy var persistentContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: "TodoApp")
    container.loadPersistentStores { _, error in
        if let error { fatalError("CoreData load failed: \(error)") }
    }
    return container
}()

// NSFetchedResultsController: SwiftData の @Query に相当
// データ変更を自動的に UITableView に反映する
let fetchRequest: NSFetchRequest<TodoEntity> = TodoEntity.fetchRequest()
fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
fetchedResultsController = NSFetchedResultsController(
    fetchRequest: fetchRequest,
    managedObjectContext: context,
    sectionNameKeyPath: nil,
    cacheName: nil
)
fetchedResultsController.delegate = self
try? fetchedResultsController.performFetch()
```

---

## Phase 7: ナビゲーション

### Step 8: Segue + prepare(for:sender:)

```swift
// go_router の GoRoute に相当する Segue
override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier {
    case "showDetail":
        guard let vc = segue.destination as? TodoDetailViewController,
              let todo = sender as? Todo else { return }
        vc.todoId = todo.id    // 依存性の注入（DI）
    case "showForm":
        guard let nav = segue.destination as? UINavigationController,
              let vc = nav.topViewController as? TodoFormViewController else { return }
        vc.editingTodo = sender as? Todo
        vc.onSave = { [weak self] todo in ... }
    default: break
    }
}
```

---

## Phase 8: 認証

### Step 9: AuthGuard（rootViewController 切り替え）

```swift
// go_router の redirect に相当
// AppDelegate 経由で SceneDelegate の window を操作
func showTodoList() {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first else { return }
    let nav = UIStoryboard(name: "Main", bundle: nil)
        .instantiateViewController(withIdentifier: "MainNav") as! UINavigationController
    UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
        window.rootViewController = nav
    }
}
```

### Step 13: JS Bridge（WKScriptMessageHandler）

```swift
// SwiftUI 版と同じ WKScriptMessageHandler を使う
// ViewController が NSObject を継承しているため適合しやすい
extension LoginWebViewController: WKScriptMessageHandler {
    func userContentController(_ controller: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard message.name == "FlutterAuth",
              let body = message.body as? String else { return }
        // JSON パースしてトークンを取得
    }
}
```

### Step 14: Keychain

SwiftUI 版と同一の `TokenStorage` enum を使い回す。

### Step 15: ASWebAuthenticationSession

```swift
// LoginViewController: ASWebAuthenticationPresentationContextProviding
extension LoginViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        view.window!
    }
}
```

SwiftUI と違い、UIKit では `presentationContextProvider` の設定が必須。
