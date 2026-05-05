# iOS Storyboard 実装仕様

共通仕様: `docs/spec.md` を参照。
本ファイルはiOS UIKit / Storyboard固有の技術選定・構成を記載する。

---

## 技術スタック

| レイヤー | 技術 |
|---|---|
| 状態管理 | ViewModel（class、手動バインディング） |
| ナビゲーション | UINavigationController + Segue / present |
| ローカルDB | CoreData（NSPersistentContainer） |
| API通信 | URLSession（async/await） |
| WebView（詳細・ログイン） | WKWebView |
| OAuth | ASWebAuthenticationSession |
| セキュアストレージ | Keychain（Security framework） |
| 最低iOS | 16.0 |

---

## ディレクトリ構成

```
Sources/
├── AppDelegate.swift
├── Config/
│   └── AppConfig.swift
├── Models/
│   └── Todo.swift               # Codable struct
├── Persistence/
│   ├── CoreDataStack.swift      # NSPersistentContainer のシングルトン
│   └── TodoStore.swift          # CoreData CRUD ラッパー
├── Network/
│   └── TodoAPIClient.swift
├── Persistence/
│   └── KeychainStore.swift
├── ViewModels/
│   ├── AuthViewModel.swift
│   └── TodoViewModel.swift
└── ViewControllers/
    ├── LoginViewController.swift
    ├── LoginWebViewController.swift   # WKWebView + WKScriptMessageHandler
    ├── TodoListViewController.swift   # UITableViewController
    ├── TodoDetailWebViewController.swift
    └── TodoFormViewController.swift

Resources/
└── Main.storyboard
```

---

## Storyboard構成

```
Initial VC: AuthRootViewController（認証状態を見てSegueを分岐）
  ├── show "login"   → LoginViewController
  │     ├── push    → LoginWebViewController
  │     └── custom  → ASWebAuthenticationSession（VC不要）
  └── show "main"   → UINavigationController
                          └── TodoListViewController
                                ├── push  → TodoDetailWebViewController
                                └── present（modal） → TodoFormViewController
```

---

## CoreData構成

`.xcdatamodeld` に以下のエンティティを定義する（Xcodeで作成）。

**エンティティ: TodoEntity**

| attribute | type | 備考 |
|---|---|---|
| id | String | |
| title | String | |
| desc | String | |
| isCompleted | Boolean | default: false |
| priority | String | default: "medium" |
| createdAt | Date | |

```swift
// CoreDataStack.swift
class CoreDataStack {
    static let shared = CoreDataStack()
    lazy var container: NSPersistentContainer = {
        let c = NSPersistentContainer(name: "TodoModel")
        c.loadPersistentStores { _, error in
            if let error { fatalError(error.localizedDescription) }
        }
        return c
    }()
    var context: NSManagedObjectContext { container.viewContext }
}
```

`NSFetchedResultsController` を `TodoListViewController` に組み込み、データ変更を自動でTableViewに反映する。

---

## 主要実装ポイント

### 認証ルーティング（AppDelegate）

```swift
func application(_ app: UIApplication,
                 open url: URL, options: ...) -> Bool {
    guard url.scheme == "todoapp",
          let token = URLComponents(url: url, resolvingAgainstBaseURL: false)
              ?.queryItems?.first(where: { $0.name == "token" })?.value
    else { return false }
    AuthViewModel.shared.login(token: token)
    return true
}
```

### JS Bridge受信（LoginWebViewController）

```swift
// WKScriptMessageHandler
func userContentController(_ controller: WKUserContentController,
                            didReceive message: WKScriptMessage) {
    guard message.name == "authBridge",
          let body = message.body as? [String: Any],
          let token = body["token"] as? String else { return }
    AuthViewModel.shared.login(token: token)
}
```

### WebViewホワイトリスト制御

SwiftUIバージョンと同じ `WKNavigationDelegate` パターンを使用。

### OAuth（ASWebAuthenticationSession）

SwiftUIバージョンと同じAPIを使用。`presentationContextProvider` に `UIWindowSceneActivationConditions` を渡す。
