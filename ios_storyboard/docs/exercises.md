# iOS Storyboard 演習課題

各 Step の手を動かす課題。理論は `learning.md` を参照。

---

## Step 1: 起動フローを理解する

1. `AppDelegate.application(...)` から `SceneDelegate.scene(...)` まで実行順をデバッガで追え
2. `SceneDelegate` の `window?.rootViewController` を変えると何が起きるか確認せよ
3. Flutter の `runApp(MaterialApp(...))` と対応付けよ

---

## Step 2: IBOutlet / IBAction を体感する

1. Storyboard に `UILabel` を追加し `@IBOutlet` で接続せよ
2. `UIButton` を追加し `@IBAction` でタップ時にラベルのテキストを変えよ
3. `@IBOutlet` と `@IBAction` の弱参照（`weak`）の意味を説明せよ

---

## Step 3: AutoLayout でレイアウトを組む

1. `UIStackView`（vertical, spacing: 16）を作り、ラベル・テキストフィールド・ボタンを縦並びにせよ
2. Storyboard のサイズインスペクタで leading/trailing を 32pt に設定せよ
3. `UISegmentedControl` で低/中/高の優先度セレクターを作れ

---

## Step 4: Todo Domain Entity を作る

1. `Todo` struct を定義せよ（SwiftUI 版と同一）
2. `TodoPriority` enum に UIColor を返す computed property を追加せよ
3. ダミーデータ `Todo.samples` を static property として用意せよ

---

## Step 5 & 6: UITableView で一覧表示

1. `UITableView` を Storyboard に配置し、`dataSource` / `delegate` を設定せよ
2. カスタムセル `TodoTableViewCell` を作り、タイトル・優先度バッジを表示せよ
3. `trailingSwipeActionsConfigurationForRowAt` で削除アクションを実装せよ
4. セルタップで `isCompleted` をトグルし、タイトルに取り消し線を表示せよ

---

## Step 7: CoreData CRUD + ViewModel + Clean Architecture

1. `.xcdatamodeld` に `TodoEntity` を定義せよ（属性: id / title / desc / isCompleted / priority / createdAt）
2. `TodoEntity+Extensions.swift` で Domain ↔ NSManagedObject のマッピングを実装せよ
3. `TodoRepositoryInterface` protocol を定義せよ
4. `TodoRepository` を CoreData で実装せよ
5. `TodoListViewModel` を実装し `onUpdate: () -> Void` クロージャで VC に通知せよ
6. `TodoListViewController` を ViewModel ベースに書き替えよ
7. `TodoFormViewController` を実装せよ（`onSave` クロージャで保存を通知）

---

## Step 8: Segue でマルチ画面を繋ぐ

1. Main.storyboard に `TodoDetailViewController`・`TodoFormViewController` を追加せよ
2. Segue を設定し、`prepare(for:sender:)` で ViewModel と TodoId を DI せよ
3. `TodoFormViewController` を Modal（Present Modally）で表示し、保存後に dismiss せよ
4. 一覧 → 詳細の遷移が動くことを確認せよ（詳細は Step 11 で WebView に置き換え）

---

## Step 9: AuthGuard（rootViewController 切り替え）

1. `LoginViewController` を Storyboard に追加し、`SceneDelegate` の初期画面に設定せよ
2. ログインボタンタップで `showTodoList()` を呼び、UINavigationController に切り替えよ
3. 一覧画面のログアウトボタンから `showLogin()` を呼べることを確認せよ
4. `UIView.transition(with:duration:options:animations:)` でアニメーション付き切り替えを実装せよ

---

## Step 10: URLSession で API 同期

1. `TodoDTO` を定義せよ
2. `TodoRemoteDataSource` を `async throws` で実装せよ
3. `TodoRepository.sync()` に重複スキップを実装せよ
4. 一覧画面のツールバーボタンから同期を呼び出し、`UIActivityIndicatorView` を表示せよ

---

## Step 11: WKWebView をコードで追加する

1. `TodoDetailViewController` の `viewDidLoad` で `WKWebView` を `view.addSubview` せよ
2. AutoLayout（`NSLayoutConstraint.activate`）で画面いっぱいに表示せよ
3. `https://jsonplaceholder.typicode.com/todos/{id}` を読み込め
4. ナビゲーションバーにリロードボタンを追加せよ

---

## Step 12: WKNavigationDelegate でホワイトリスト制御

1. `WebViewConfig.allowedHosts` を定義せよ（SwiftUI 版と共有可）
2. `webView(_:decidePolicyFor:decisionHandler:)` でブロックを実装せよ
3. ブロック時に `UIAlertController` でホスト名を表示せよ

---

## Step 13: ログイン WebView + JS Bridge

1. `LoginWebViewController` を作り、`login.html` をバンドルからロードせよ
2. `WKUserContentController.add(_:name:)` で `FlutterAuth` チャネルを登録せよ
3. `WKScriptMessageHandler` でトークンを受取り、`LoginViewController` に通知せよ

---

## Step 14: Keychain でトークン管理

1. SwiftUI 版の `TokenStorage` を再利用し、保存・読み込み・削除を確認せよ
2. `SceneDelegate.scene(...)` で Keychain を確認し、トークンがあれば直接一覧へ遷移せよ
3. ログアウト時にトークンを削除して LoginViewController に戻せ

---

## Step 15: OAuth フロー（ASWebAuthenticationSession）

1. `LoginViewController` に「OAuth でログイン」ボタンを追加せよ
2. `ASWebAuthenticationPresentationContextProviding` に準拠せよ
3. `ASWebAuthenticationSession` で `todoapp://callback?token=...` を受け取れ
4. 受取後 `TokenStorage.save()` → `showTodoList()` の流れを実装せよ
