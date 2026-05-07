# iOS SwiftUI 演習課題

各 Step の手を動かす課題。理論は `learning.md` を参照。

---

## Step 1: View ツリーを理解する

1. `TodoApp.swift` の `@main` から `ContentView` までのツリーを追い、Flutter の `runApp → MaterialApp → Scaffold` と対応づけよ
2. `Text("Hello, World!")` の下に `Text("副題")` を追加し、`VStack` で縦並びにせよ
3. `font(.title)` / `foregroundStyle(.blue)` / `padding()` の Modifier をそれぞれ試せ

---

## Step 2: 状態管理を体感する

1. `@State private var count = 0` を使ってタップするたびに数字が増えるボタンを作れ
2. 親から `@Binding` でカウントを渡し、子 View からインクリメントできるようにせよ
3. `@Observable` な `CounterViewModel` を作り、`@State var viewModel = CounterViewModel()` で Screen に持たせよ

---

## Step 3: レイアウトを触る

1. `HStack` で優先度バッジ（赤/橙/緑の丸）とタイトルを横並びにせよ
2. `Spacer()` を使って左右に要素を分散させよ（Flutter の `MainAxisAlignment.spaceBetween` 相当）
3. `ZStack` でカードの右上にバッジをオーバーレイせよ

---

## Step 4: Todo Domain Entity を作る

1. `Todo` struct を定義せよ（id / title / description / isCompleted / priority / createdAt）
2. `TodoPriority` enum を定義し、`label` と `color` の computed property を実装せよ
3. ダミーデータ `Todo.samples: [Todo]` を static property として用意せよ

---

## Step 5 & 6: リスト表示とインタラクション

1. `List { ForEach(todos) { TodoCard(todo: $0) } }` で一覧を表示せよ
2. `swipeActions` で削除ボタンを追加せよ
3. タップで `isCompleted` をトグルし、完了済みタイトルに取り消し線を表示せよ

---

## Step 7: SwiftData で CRUD + ViewModel + Clean Architecture

1. `TodoItem` (`@Model`) を作り、`Todo` との相互変換メソッドを実装せよ
2. `TodoRepositoryInterface` protocol を定義せよ（load / save / toggle / delete / sync）
3. `TodoRepository` を実装し、SwiftData ModelContext を使って CRUD せよ
4. `@Observable TodoListViewModel` を実装せよ（状態: todos / filter / isLoading / errorMessage）
5. `TodoListView` を ViewModel ベースに書き替えよ
6. `TodoFormView` と `TodoFormViewModel` を実装せよ

---

## Step 8: NavigationStack でマルチ画面を繋ぐ

1. `AppRoute` enum を定義せよ（todoDetail / todoForm）
2. `@Observable AppRouter` を実装せよ（path / push / pop / replaceRoot）
3. `NavigationStack(path: $router.path)` に `navigationDestination` を設定し、一覧→詳細→フォームを繋げよ
4. `TodoDetailWebView` でダミー URL を表示せよ（次 Step で本実装）
5. フォームを Modal（`sheet`）で表示せよ

---

## Step 9: AuthGuard を追加する

1. `AuthViewModel` に `isLoggedIn` を追加せよ
2. `AppRouter` の `isLoggedIn` で `Group { if ... LoginView else NavigationStack }` を切り替えよ
3. ログアウトボタンを一覧画面に追加し、LoginView に戻れることを確認せよ

---

## Step 10: URLSession で API 同期

1. `TodoDTO` を定義せよ（id / title / completed）
2. `TodoRemoteDataSource` を実装し、`async throws` で `[TodoDTO]` を返せ
3. `TodoRepository.sync()` を実装し、重複スキップロジックを入れよ
4. 一覧画面の同期ボタンから呼び出し、ローディングインジケーターを表示せよ

---

## Step 11: WKWebView を UIViewRepresentable でラップする

1. `WebViewRepresentable: UIViewRepresentable` を作り、URL を受け取って表示せよ
2. `TodoDetailWebView` で `https://jsonplaceholder.typicode.com/todos/{id}` を表示せよ
3. ナビゲーションバーにリロードボタンを追加せよ

---

## Step 12: ホワイトリスト制御

1. `WebViewConfig.allowedHosts` を定義せよ
2. `WKNavigationDelegate` でホスト外への遷移をブロックせよ
3. ブロック時に `Alert` でホスト名を表示せよ

---

## Step 13: ログイン WebView + JS Bridge

1. `login.html`（assets）を WKWebView でローカルロードせよ
2. `WKScriptMessageHandler` で `FlutterAuth` チャネルを受信せよ
3. 受信したトークンをコールバックで `AuthViewModel` に渡せ

---

## Step 14: Keychain でトークン管理

1. `TokenStorage` を実装せよ（save / load / delete、Security framework 使用）
2. アプリ起動時に Keychain を確認し、トークンがあれば TodoListView、なければ LoginView を表示せよ
3. ログアウト時にトークンを削除せよ

---

## Step 15: OAuth フロー（ASWebAuthenticationSession）

1. LoginView に「OAuth でログイン」ボタンを追加せよ
2. `ASWebAuthenticationSession` を使い `todoapp://callback?token=mock_oauth_token` を受け取れ
3. 受取後 TokenStorage に保存し TodoListView に遷移せよ
