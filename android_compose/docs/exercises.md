# Android Compose 演習シート（手を動かす）

PC前でコードを書くときに開く実践シート。
概念の説明は `learning.md` を参照。

---

## Phase 1: Jetpack Compose の基礎

### Step 1: Composable ツリーを読む

**やること**

1. Android Studio で `android_compose/` を新規作成（Empty Activity / Compose）
2. `MainActivity.kt` を開いて `setContent { }` の中の Composable ツリーを上から追う
3. `MaterialTheme` → `Scaffold` → `Column` の入れ子を確認
4. `colorScheme` の `primary` を `Color(0xFF4CAF50)`（緑）に変えて確認
5. 実機/エミュレーターでホットリロード（ファイル保存）して色が変わることを確認

**確認ポイント**
- Flutter の `Hot Reload` に相当するのが Android Studio の `Apply Changes`
- `MaterialTheme.colorScheme.primary` が seedColor から自動生成されていることを確認

---

### Step 2: Stateless / Stateful Composable を自作する

**現在の構成**（Step 2 完了時点）

```
MainActivity
  └── setContent
        └── CounterScreen（状態を持つ）
              ├── CounterDisplay（count を受け取るだけ）
              └── CounterButtons（onIncrement / onDecrement を受け取るだけ）
```

**やること**

1. `CounterDisplay` を `@Composable fun CounterDisplay(count: Int)` として作る（引数のみ）
2. `CounterScreen` で `var count by remember { mutableStateOf(0) }` を持つ
3. `+` ボタンで `count++`、`-` ボタンで `count--` が動くことを確認
4. `CounterDisplay` の `TextStyle` を `MaterialTheme.typography.displayLarge` → `displayMedium` に変えて確認
5. **追加課題**: `count > 0` / `< 0` / `== 0` でラベルを切り替える `CounterLabel` を追加する

---

### Step 3: レイアウト Composable を触る

**現在の構成**（Step 3 完了時点）

```
TodoListScreen（Scaffold）
  ├── TopAppBar
  ├── Column
  │     ├── FilterTabBar（Row + weight × 3 でタブを均等分割）
  │     └── LazyColumn（TodoCard のリスト）
  └── FloatingActionButton
```

**やること**

1. エミュレーターで TODO リストのダミー画面が表示されることを確認
2. `FilterTabBar` の `Modifier.weight(1f)` を外してみる → タブが横幅を取らなくなることを確認
3. `TodoCard` の `Row` の `horizontalArrangement` を変えてみる
4. `TodoCard` に `description` を追加して `Column` を入れ子にする（`learning.md` Step 3 参照）
5. **追加課題**: `LazyColumn` の `items` に `key = { it.id }` を追加して、リストの再描画を最適化する

---

## Phase 2: TODO一覧画面（UIだけ）

### Step 4: モデルクラス Todo を作る

**作成するファイル**: `features/todo/Todo.kt`

**やること**

1. `data class Todo` と `enum class TodoPriority / TodoFilter` を作る
2. `copy()` を使って `isCompleted` を反転した新しい `Todo` を作り、`Log.d` で確認する
3. ダミーデータ（`val dummyTodos = listOf(...)` ）を `TodoListScreen` で使って表示する
4. **追加課題**: `TodoPriority` ごとに色を返す `extension val TodoPriority.color: Color` を `Screen` 層に書く

---

### Step 5 & 6: インタラクションを追加する

**やること**

1. `TodoListScreen` で `var todos by remember { mutableStateOf(dummyTodos) }` と `var filter by remember { mutableStateOf(TodoFilter.ALL) }` を持つ
2. チェックアイコンをタップ → `copy(isCompleted = !todo.isCompleted)` で更新されることを確認
3. フィルタータブをタップ → `when(filter)` で絞り込まれることを確認
4. `SwipeToDismissBox` でスワイプ削除を実装する
5. **追加課題**: フィルター「ACTIVE」に切り替えた後、チェックをつけるとリストから消えることを確認

---

## Phase 3: 永続化（Room）

### Step 7: Room で CRUD を実装する

**作成するファイル**

```
features/todo/data/local/
  TodoEntity.kt
  TodoDao.kt
  AppDatabase.kt
  TodoLocalDataSource.kt
features/todo/
  TodoRepositoryInterface.kt
  TodoRepository.kt
  TodoListViewModel.kt
```

**やること**

1. `TodoEntity` / `TodoDao` / `AppDatabase` を作成する
2. `TodoLocalDataSource` で `observeAll(): Flow<List<Todo>>` を実装する
3. `TodoListViewModel` で `init { viewModelScope.launch { repository.observeAll().collect { ... } } }` を実装する
4. `TodoListScreen` で `val viewModel: TodoListViewModel = viewModel(factory = ...)` を使う
5. `collectAsState()` で `State<TodoListState>` を取得して画面に反映する
6. アプリを再起動して Todo が保持されることを確認する
7. **確認ポイント**: `StateFlow` の `update { it.copy(...) }` で Compose が再描画されることを確認

---

## Phase 4: ナビゲーション（Navigation Compose）

### Step 8: 一覧 → 詳細 → 編集フォームを繋ぐ

**やること**

1. `navigation-compose` 依存を `build.gradle.kts` に追加する
2. `AppNavGraph.kt` を作成し `NavHost` でルートを定義する
3. `TodoListScreen` の Todo タップで `navController.navigate("todo/${todo.id}")` する
4. `TodoDetailScreen` で `backStackEntry.arguments?.getString("id")` から Todo を探して表示する
5. `TodoFormScreen` をモーダル（`showAsDialog` または `Dialog { }` ）で表示する
6. **確認ポイント**: 戻るボタンで正しく前の画面に戻ることを確認

---

### Step 9: AuthGuard を追加する

**やること**

1. `AuthViewModel` を作成し `_state.update { it.copy(isLoggedIn = false) }` で未ログイン状態にする
2. `AppNavGraph` 内で `LaunchedEffect(authState.isLoggedIn)` を追加して未ログイン時に `"login"` にリダイレクトする
3. ログインボタンタップで `authViewModel.loginWithToken("mock_token")` を呼ぶ
4. ログイン状態が変わると自動でリダイレクトされることを確認する
5. **確認ポイント**: ログイン済みで `"login"` ルートに遷移しようとすると `"home"` に飛ばされることを確認

---

## Phase 5: API連携（Ktor Client）

### Step 10: JSONPlaceholder から Todo を取得・同期する

**やること**

1. `build.gradle.kts` に Ktor Client 依存を追加する
   - `io.ktor:ktor-client-android`
   - `io.ktor:ktor-client-content-negotiation`
   - `io.ktor:ktor-serialization-kotlinx-json`
2. `TodoDto` を `@Serializable data class` として作成する
3. `TodoRemoteDataSource` で `client.get("/todos") { parameter("_limit", 20) }.body<List<TodoDto>>()` を実装する
4. `TodoRepository.sync()` で重複スキップ（`filter { it.id !in existing }`）を実装する
5. `TodoListViewModel` に `sync()` 関数を追加し、AppBar の同期ボタンで呼び出す
6. ネットワークエラー時に `try/catch` で `state.copy(error = "...")` を設定してスナックバーを表示する
7. **確認ポイント**: `AndroidManifest.xml` に `<uses-permission android:name="android.permission.INTERNET" />` があることを確認

---

## Phase 6: WebView

### Step 11: AndroidView で WebView を表示する

**やること**

1. `WebViewScreen.kt` を作成し `AndroidView { context -> WebView(context).apply { ... } }` を実装する
2. `isLoading` を `remember { mutableStateOf(true) }` で持ち、`onPageFinished` で `false` に切り替える
3. `Box` で `WebViewWidget` と `CircularProgressIndicator` を重ねてローディング表示を実装する
4. `TodoListScreen` の AppBar に「Web で開く」ボタンを追加し、`navController.navigate("webview?url=...")` で遷移する
5. **確認ポイント**: `settings.javaScriptEnabled = true` がないと JS が動かないことを確認

---

### Step 12: ホワイトリスト制御を実装する

**やること**

1. `config/WebViewConfig.kt` を作成し `allowedHosts = listOf("localhost", "127.0.0.1")` を定義する
2. `WebViewClient.shouldOverrideUrlLoading` でホワイトリスト外をブロックする
3. ブロック時は `CustomTabsIntent` で外部ブラウザに渡す
4. `docker-compose up -d`（`zed/flutter/` で実行）でローカル nginx を起動する
5. `http://10.0.2.2:8080`（エミュレーターから localhost への特殊 IP）でアクセスできることを確認する
6. ホワイトリスト外のリンクがブロックされて Chrome で開くことを確認する

> **エミュレーターの localhost**: Android エミュレーターから Mac の localhost は `10.0.2.2` でアクセスする（実機は IP アドレスで）。

---

## Phase 7: 認証

### Step 13: ログイン画面（WebView + JavaScript Interface）

**やること**

1. `assets/login.html` を配置する（Flutter 版の `html/login.html` をベースに流用可能）
2. `LoginWebViewScreen` で `addJavascriptInterface(FlutterAuthBridge(...), "FlutterAuth")` を設定する
3. HTML のログインボタン押下 → JS Bridge → `authViewModel.loginWithToken(token)` の流れを確認する
4. トークン受信後に `LaunchedEffect` で `"home"` へ遷移することを確認する
5. **セキュリティ確認**: `@JavascriptInterface` のないメソッドが JS から呼べないことを確認する

---

### Step 14: EncryptedSharedPreferences でトークン管理

**やること**

1. `build.gradle.kts` に `androidx.security:security-crypto` を追加する
2. `TokenStorage.kt` を作成し `EncryptedSharedPreferences` でトークンを読み書きする
3. `AuthViewModel.init` でアプリ起動時にトークンを読み込み、自動ログインを実装する
4. ログアウトボタンでトークン削除 → LoginScreen へリダイレクトされることを確認する
5. アプリを完全終了 → 再起動してもログイン状態が保持されることを確認する
6. **確認ポイント**: `minSdk 26` が必要なことを確認する（`EncryptedSharedPreferences` の要件）

---

### Step 15: OAuth フロー（Chrome Custom Tabs）

**やること**

1. `build.gradle.kts` に `androidx.browser:browser` を追加する
2. `AndroidManifest.xml` に `todoapp://callback` の Intent filter を追加する
3. `LoginWebViewScreen` で `type: 'oauth'` メッセージを受け取ったら `CustomTabsIntent` で認可 URL を開く
4. `html/oauth/authorize.html` を配置してモック認可フローを作る（Flutter 版と共通）
5. `MainActivity.onNewIntent` でコールバック URL を受け取り `authViewModel.handleOAuthCallback(code)` を呼ぶ
6. OAuth ログイン後に TodoList へ遷移することをエンドツーエンドで確認する
7. **確認ポイント**: `android:launchMode="singleTop"` が `MainActivity` に設定されていることを確認（`onNewIntent` を受け取るため）
