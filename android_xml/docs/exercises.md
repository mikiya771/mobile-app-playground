# Android XML 演習シート（手を動かす）

PC前でコードを書くときに開く実践シート。
概念の説明は `learning.md` を参照。

---

## Phase 1: XML 基礎

### Step 1: Activity と ViewBinding を読む

**やること**

1. Android Studio で `android_xml/` を開く（Empty Views Activity）
2. `MainActivity.kt` を開いて `setContentView(binding.root)` の流れを追う
3. `activity_main.xml` を開いて View ツリーを確認する
4. `binding.helloText.setTextColor(ContextCompat.getColor(this, R.color.priority_high))` でテキストを赤にする
5. Apply Changes でホットリロードして色が変わることを確認する

**確認ポイント**

- `ActivityMainBinding.inflate(layoutInflater)` が Compose の `setContent { }` に相当
- `binding.helloText` がコンパイル時に型チェックされることを確認（存在しないIDはコンパイルエラー）
- `R.id.xxx` を使う `findViewById` との違いを把握する

---

### Step 2: RecyclerView + ListAdapter を実装する

**現在の構成**（Step 2 完了時点）

```
MainActivity
  └── activity_main.xml
        └── RecyclerView
              └── TodoAdapter（ListAdapter<Todo, TodoViewHolder>）
                    └── item_todo.xml
```

**やること**

1. `item_todo.xml` を作成する（`MaterialCardView` + `TextView` × 2）
2. `TodoAdapter.kt` を作成する（`ListAdapter` + `DiffUtil.ItemCallback`）
3. `TodoViewHolder.kt` を `TodoAdapter` 内に定義する
4. `MainActivity.kt` で `RecyclerView` に `LinearLayoutManager` と `TodoAdapter` を設定する
5. ダミーデータを `adapter.submitList(dummyTodos)` で表示して確認する
6. **確認ポイント**: `submitList()` が Compose の `items(todos)` に相当することを確認

---

### Step 3: ConstraintLayout でレイアウトを組む

**現在の構成**（Step 3 完了時点）

```
activity_main.xml
  ├── Toolbar (AppBar)
  ├── LinearLayout（FilterTabBar: 3 ボタン均等）
  └── RecyclerView（TodoCard のリスト）

item_todo.xml（ConstraintLayout）
  ├── PriorityBadge（TextView with backgroundTint）
  ├── title（TextView）
  ├── description（TextView）
  └── checkIcon（ImageView）
```

**やること**

1. `activity_main.xml` にフィルタータブ（3ボタン `LinearLayout` + `layout_weight="1"`）を追加する
2. `item_todo.xml` を `ConstraintLayout` に書き換えて `description` を追加する
3. `TodoAdapter.bind()` で `todo.priority.color` を `priorityBadge.backgroundTintList` に設定する
4. `layout_weight="1"` を外すとタブが均等にならないことを確認する（Compose の `Modifier.weight(1f)` 相当）
5. **追加課題**: `item_todo.xml` に `isCompleted` に応じて取り消し線（`Paint.STRIKE_THRU_TEXT_FLAG`）を切り替える

---

## Phase 2: TODO 一覧画面（UI だけ）

### Step 4: モデルクラス Todo を作る

**作成するファイル**: `features/todo/Todo.kt`

**やること**

1. `data class Todo` と `enum class TodoPriority / TodoFilter` を作る
2. `copy()` を使って `isCompleted` を反転した新しい `Todo` を作り、`Log.d` で確認する
3. ダミーデータを `TodoAdapter.submitList(dummyTodos)` で表示する
4. **追加課題**: `TodoPriority` ごとにリソース色を返す `extension val TodoPriority.colorRes: Int` を書く

---

### Step 5 & 6: インタラクションを追加する

**やること**

1. `TodoListViewModel` で `MutableLiveData<List<Todo>>` と `MutableLiveData<TodoFilter>` を持つ
2. `Fragment` で `viewModel.todos.observe(viewLifecycleOwner) { adapter.submitList(it) }` を実装する
3. チェックアイコンタップ → `copy(isCompleted = !todo.isCompleted)` で更新されることを確認する
4. フィルタータブタップ → `when(filter)` で絞り込まれることを確認する
5. RecyclerView の `ItemTouchHelper` でスワイプ削除を実装する
6. **追加課題**: フィルター「ACTIVE」に切り替えた後、チェックをつけるとリストから消えることを確認する

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
  TodoListViewModel.kt（Room 版に更新）
```

**やること**

1. `TodoEntity` / `TodoDao` / `AppDatabase` を作成する
2. `TodoDao.observeAll()` で `LiveData<List<TodoEntity>>` を返す
3. `TodoListViewModel` で `repository.observeAll().observe(viewLifecycleOwner)` を実装する
4. アプリを再起動して Todo が保持されることを確認する
5. **確認ポイント**: `submitList()` が呼ばれるたびに `DiffUtil` が差分計算して最小限の更新を行うことを確認する

---

## Phase 4: ナビゲーション（Navigation Component）

### Step 8: NavGraph XML で画面遷移を実装する

**やること**

1. `res/navigation/nav_graph.xml` を作成し、Fragment を定義する
2. `activity_main.xml` に `FragmentContainerView` を配置し `navGraph` を設定する
3. `TodoListFragment` の Todo タップで `navController.navigate(R.id.action_list_to_detail)` する
4. `TodoDetailFragment` で `args.todoId` から Todo を探して表示する
5. **確認ポイント**: 戻るボタンで正しく前の画面に戻ることを確認する（`defaultNavHost="true"` の効果）

---

### Step 9: AuthGuard を追加する

**やること**

1. `AuthViewModel` を作成し `_isLoggedIn = MutableLiveData(false)` で未ログイン状態にする
2. `MainActivity` の `navController.addOnDestinationChangedListener` で未ログイン時に `loginFragment` にリダイレクトする
3. ログインボタンタップで `authViewModel.loginWithToken("mock_token")` を呼ぶ
4. ログイン状態が変わると自動でリダイレクトされることを確認する
5. **確認ポイント**: Compose の `LaunchedEffect(authState.isLoggedIn)` との動作の違いを比較する

---

## Phase 5: API 連携（Retrofit）

### Step 10: Retrofit で JSONPlaceholder から Todo を取得・同期する

**やること**

1. `app/build.gradle.kts` に Retrofit + OkHttp 依存を確認する（既に追加済み）
2. `TodoDto` を `data class` として作成する（`@SerializedName` でフィールド名変換）
3. `TodoApiService` インターフェースに `@GET("todos") suspend fun fetchTodos()` を定義する
4. `TodoRemoteDataSource` で Retrofit インスタンスを作成して `fetchTodos()` を呼ぶ
5. `TodoRepository.sync()` で重複スキップ（`filter { it.id !in existing }`）を実装する
6. `TodoListViewModel` に `sync()` 関数を追加し、Toolbar の同期ボタンで呼び出す
7. **確認ポイント**: `AndroidManifest.xml` に `INTERNET` パーミッションがあることを確認

---

## Phase 6: WebView

### Step 11: WebView を実装する

**やること**

1. `WebViewFragment.kt` を作成し `fragment_webview.xml` に `WebView` + `ProgressBar` を配置する
2. `WebViewClient.onPageStarted` で `ProgressBar` を表示、`onPageFinished` で非表示にする
3. `TodoListFragment` の Toolbar に「Web で開く」メニューを追加し、`navigate(R.id.webViewFragment)` で遷移する
4. **確認ポイント**: `settings.javaScriptEnabled = true` がないと JS が動かないことを確認する
5. **Compose との比較**: XML では `WebView` をレイアウトに直接置ける（`AndroidView {}` ラッパーが不要）

---

### Step 12: ホワイトリスト制御を実装する

**やること**

1. `config/WebViewConfig.kt` を作成し `allowedHosts = listOf("localhost", "127.0.0.1", "10.0.2.2")` を定義する
2. `WebViewClient.shouldOverrideUrlLoading` でホワイトリスト外をブロックする
3. ブロック時は `CustomTabsIntent` で外部ブラウザに渡す
4. ホワイトリスト外のリンクがブロックされて Chrome で開くことを確認する

---

## Phase 7: 認証

### Step 13: ログイン画面（WebView + JavaScript Interface）

**やること**

1. `assets/login.html` を配置する（Compose 版と共通）
2. `LoginFragment` で `webView.addJavascriptInterface(FlutterAuthBridge(...), "FlutterAuth")` を設定する
3. HTML のログインボタン押下 → JS Bridge → `authViewModel.loginWithToken(token)` の流れを確認する
4. `onDestroyView` で `removeJavascriptInterface("FlutterAuth")` を呼ぶ（リークを防ぐ）
5. **セキュリティ確認**: `@JavascriptInterface` のないメソッドが JS から呼べないことを確認する

---

### Step 14: EncryptedSharedPreferences でトークン管理

**やること**

1. `TokenStorage.kt` を作成し `EncryptedSharedPreferences` でトークンを読み書きする
2. `AuthViewModel.init` でアプリ起動時にトークンを読み込み、自動ログインを実装する
3. ログアウトボタンでトークン削除 → `LoginFragment` へリダイレクトされることを確認する
4. アプリを完全終了 → 再起動してもログイン状態が保持されることを確認する

---

### Step 15: OAuth フロー（Chrome Custom Tabs）

**やること**

1. `AndroidManifest.xml` に `todoapp://callback` の Intent filter を確認する（初期設定済み）
2. `LoginFragment` で `type: 'oauth'` メッセージを受け取ったら `CustomTabsIntent` で認可 URL を開く
3. `assets/oauth/authorize.html` を配置してモック認可フローを作る（Compose 版と共通）
4. `MainActivity.onNewIntent` でコールバック URL を受け取り `authViewModel.handleOAuthCallback(code)` を呼ぶ
5. OAuth ログイン後に TodoList へ遷移することをエンドツーエンドで確認する
6. **確認ポイント**: `android:launchMode="singleTop"` が `MainActivity` に設定されていることを確認
