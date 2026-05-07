# Android Compose 学習ノート（読み物）

外出先でも読める概念まとめ。手を動かす課題は `exercises.md` を参照。

---

## 進捗

- [x] Step 1: MainActivity を読んで Composable ツリーを理解する
- [x] Step 2: Stateless / Stateful Composable の違いを体感する
- [ ] Step 3: レイアウト Composable（Column / Row / Box / Modifier）を触る
- [x] Step 4: モデルクラス Todo を作る
- [x] Step 5 & 6: インタラクションを追加する（State hoisting）
- [x] Step 7: Room で CRUD を実装する / ViewModel + MVVM + Clean Architecture 導入
- [x] Step 8: 一覧 → 詳細WebView → 編集フォームを繋ぐ（Navigation Compose）
- [x] Step 9: AuthGuard を追加する
- [x] Step 10: JSONPlaceholder から Todo を取得・同期する（Ktor Client）
- [x] Step 11: AndroidView で WebView を表示する
- [x] Step 12: ホワイトリスト制御を実装する
- [x] Step 13: ログイン画面（WebView + JavaScript Interface）
- [x] Step 14: EncryptedSharedPreferences でトークン管理・AuthGuard
- [x] Step 15: OAuth フロー（Chrome Custom Tabs）

---

## アーキテクチャ方針

### Composable の使用ルール

| アクセス方法 | Composable 層 | Screen 層 |
|---|---|---|
| `MaterialTheme.*` | ✅ 許容 | ✅ 許容 |
| `LocalConfiguration` | ❌ 引数で渡す | ✅ 許容 |
| `navController.navigate()` | ❌ コールバックで渡す | ✅ 許容 |
| `viewModel()` / `collectAsState()` | ❌ | ✅ 許容 |
| `LocalContext` | ❌ | ✅ 許容 |

**理由**: Flutter の「ウィジェット層は context を直接触らない」と同じ原則。  
Composable 層が `navController` を直接持つと置き場所が制約される。

### データフローの原則

```
ViewModel（StateFlow<State>）
  ↓ collectAsState()
Screen Composable（ref.watch 相当）
  ↓ 引数で下に流す（prop drilling）
子 Composable（引数だけを見る）
  ↓ lambda（コールバック）で上に返す
ViewModel（状態更新）
```

- **`viewModel()` / `collectAsState()` は Screen 層にのみ書く**
- **子 Composable は引数と lambda だけを受け取る**

### Flutter との対応

| Flutter / Riverpod | Android Compose |
|---|---|
| `ref.watch(todoListProvider)` | `viewModel.state.collectAsState()` |
| `state.copyWith(...)` | `state.copy(...)` |
| `Notifier.build()` の `_load()` | `ViewModel.init { viewModelScope.launch { load() } }` |
| `ProviderScope` | `ViewModelStoreOwner`（Activity/Fragment） |

---

## Phase 1: Jetpack Compose の基礎

### Step 1: Composable ツリーとは何か

Compose の UI はすべて **`@Composable` 関数の入れ子（ツリー）** で表現される。  
Flutter の Widget ツリーに相当するが、クラスではなく関数で記述する。

```kotlin
// Flutter の Widget ツリーに対応する Compose ツリー
setContent {
    MaterialTheme {           // テーマ設定（MaterialApp に相当）
        Scaffold(             // 画面の骨格
            topBar = { ... }
        ) { padding ->
            Column(           // 縦方向レイアウト
                modifier = Modifier.padding(padding)
            ) {
                Text("Hello")
            }
        }
    }
}
```

**`MaterialTheme` が提供するもの**

| 機能 | 詳細 |
|---|---|
| カラー | `MaterialTheme.colorScheme.*` |
| タイポグラフィ | `MaterialTheme.typography.*` |
| シェイプ | `MaterialTheme.shapes.*` |

Flutter の `Theme.of(context)` が `MaterialTheme.*` に対応する。

**注意: `dynamicColor = true`（デフォルト）の落とし穴**

Android 12 以降は `dynamicColor = true` のとき OS の壁紙色が `primary` に優先される。  
自分で定義した色を確認したい場合は `dynamicColor = false` を明示する必要がある。

---

**Compose はリコンポーズ（再描画）で UI を更新する**

`state` が変化すると Compose ランタイムがそのブロックだけを再実行する。  
Flutter の `setState()` → `build()` 再実行と同じ仕組みだが、差分検出がより細粒度。

---

### Step 2: Stateless / Stateful Composable

**どちらを使うかの判断**

| 状況 | 選択 |
|---|---|
| 引数を受け取って描画するだけ | Stateless（ただの `@Composable`） |
| タップ・入力などローカル状態が必要 | `remember { mutableStateOf() }` |
| ビジネス状態が必要 | ViewModel + `collectAsState()` |

**Stateless（引数のみ）**

```kotlin
@Composable
fun PriorityBadge(priority: TodoPriority) {
    val (label, color) = when (priority) {
        TodoPriority.LOW    -> "低" to Color(0xFF4CAF50)
        TodoPriority.MEDIUM -> "中" to Color(0xFFFF9800)
        TodoPriority.HIGH   -> "高" to Color(0xFFF44336)
    }
    Surface(color = color, shape = RoundedCornerShape(4.dp)) {
        Text(label, modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp))
    }
}
```

Flutter の `StatelessWidget` に相当。`const` コンストラクタが使える StatelessWidget のように、引数が同じなら Compose は再描画をスキップできる。

**Stateful（remember + mutableStateOf）**

```kotlin
@Composable
fun FilterTabBar(selected: TodoFilter, onSelect: (TodoFilter) -> Unit) {
    // UIローカル状態: このコンポーザブル内だけで完結
    // ← Flutter の StatefulWidget の _state に相当
    var rippleTarget by remember { mutableStateOf<TodoFilter?>(null) }
    ...
}
```

`remember { }` は Composable のライフタイムを通じて値を保持する。  
Flutter の `State` オブジェクトが Widget の再生成をまたいで生き続けるのと同じ。

**State hoisting（状態の引き上げ）**

```kotlin
// NG: Composable が自分で状態を持つ（テスト・再利用が難しくなる）
@Composable
fun TodoCard() {
    var isCompleted by remember { mutableStateOf(false) }
}

// OK: 状態を上に引き上げ、引数とコールバックで渡す
@Composable
fun TodoCard(todo: Todo, onToggle: (String) -> Unit) {
    // todo は引数（下に流す）、onToggle は lambda（上に返す）
}
```

Flutter の「データは引数で下に流す / イベントはコールバックで上に返す」と同一原則。

---

### Step 3: レイアウト Composable

Flutter のレイアウト Widget との対応表。

| Flutter | Android Compose | 役割 |
|---|---|---|
| `Column` | `Column` | 縦方向に並べる |
| `Row` | `Row` | 横方向に並べる |
| `Container` | `Box` + `Modifier` | サイズ・色・余白 |
| `Padding` | `Modifier.padding()` | 余白 |
| `SizedBox` | `Spacer()` / `Modifier.size()` | 固定サイズの空白 |
| `Expanded` | `Modifier.weight(1f)` | 残りスペースを占有 |
| `Card` | `Card { }` | 影付きカード |
| `Stack` | `Box` | 重ね合わせ |

**Modifier チェーン**

Compose のレイアウトは `Modifier` のチェーンで表現する。CSS のように左から右へ適用される。

```kotlin
// Flutter: Container(padding: EdgeInsets.all(16), color: Colors.blue, child: Text(...))
Box(
    modifier = Modifier
        .fillMaxWidth()           // width: 100%
        .padding(16.dp)           // padding: 16
        .background(Color.Blue)   // background-color: blue
) {
    Text("hello")
}
```

**`weight` で Expanded を表現する**

```kotlin
// Flutter: Row( children: [Text('A'), Expanded(child: Text('B')), Text('C')] )
Row {
    Text("A")
    Text("B", modifier = Modifier.weight(1f))  // ← 残りスペースを使う
    Text("C")
}
```

---

## Phase 2: TODO一覧画面（UIだけ）

### Step 4: モデルクラス Todo を作る

**Kotlin の `data class` は `copyWith` を自動生成する**

```kotlin
// Flutter: Todo クラスに copyWith() を手書きした
// Kotlin: data class は copy() を自動生成する

data class Todo(
    val id: String,
    val title: String,
    val description: String = "",
    val isCompleted: Boolean = false,
    val priority: TodoPriority = TodoPriority.MEDIUM,
    val createdAt: Long,  // エポックミリ秒
)

enum class TodoPriority { LOW, MEDIUM, HIGH }
enum class TodoFilter { ALL, ACTIVE, COMPLETED }

// 使い方（Flutter の copyWith と同じ）
val updated = todo.copy(isCompleted = !todo.isCompleted)
```

**UI レイヤーでの変換**

モデルに `Color` / `Composable` は持たせない。UI 変換は Screen / Component 層で行う。

```kotlin
// NG: モデルに UI 依存を持たせる
data class Todo(val color: Color)

// OK: Screen で変換する
val color = when (todo.priority) {
    TodoPriority.LOW    -> Color(0xFF4CAF50)
    TodoPriority.MEDIUM -> Color(0xFFFF9800)
    TodoPriority.HIGH   -> Color(0xFFF44336)
}
```

---

### Step 5 & 6: インタラクションと State hoisting

**`when` 式（Kotlin の switch 式）**

```kotlin
// Flutter の Dart 3 switch 式に対応
val filtered = when (filter) {
    TodoFilter.ALL       -> todos
    TodoFilter.ACTIVE    -> todos.filter { !it.isCompleted }
    TodoFilter.COMPLETED -> todos.filter { it.isCompleted }
}
```

Kotlin の `when` は全ケースを網羅しないとコンパイルエラー（`when` が式として使われる場合）。Flutter の `switch` 式と同じ安全性。

**`SwipeToDismiss` でスワイプ削除**

```kotlin
// Flutter の Dismissible に相当
val dismissState = rememberSwipeToDismissBoxState(
    confirmValueChange = { it == SwipeToDismissBoxValue.EndToStart }
)
SwipeToDismissBox(
    state = dismissState,
    backgroundContent = { /* 赤い背景 */ },
) {
    TodoCard(todo = todo, onToggle = onToggle)
}
LaunchedEffect(dismissState.currentValue) {
    if (dismissState.currentValue == SwipeToDismissBoxValue.EndToStart) {
        onDelete(todo.id)
    }
}
```

---

## Phase 3: 永続化（Room）

### Step 7: Room + ViewModel + MVVM + Clean Architecture

#### Room による永続化

Room は SQLite の Kotlin 製 ORM。`sqflite` + `openDatabase` に相当するが、アノテーションで型安全にアクセスできる。

```kotlin
// 1. Entity（テーブル定義）← sqflite の CREATE TABLE に相当
@Entity(tableName = "todos")
data class TodoEntity(
    @PrimaryKey val id: String,
    val title: String,
    val description: String = "",
    val isCompleted: Boolean = false,
    val priority: String = "medium",
    val createdAt: Long,
)

// 2. Dao（SQL操作のインターフェース）
@Dao
interface TodoDao {
    @Query("SELECT * FROM todos ORDER BY createdAt DESC")
    fun observeAll(): Flow<List<TodoEntity>>   // Flow で変更を監視

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: TodoEntity)

    @Update
    suspend fun update(entity: TodoEntity)

    @Query("DELETE FROM todos WHERE id = :id")
    suspend fun delete(id: String)
}

// 3. Database
@Database(entities = [TodoEntity::class], version = 1)
abstract class AppDatabase : RoomDatabase() {
    abstract fun todoDao(): TodoDao
}
```

#### Room Entity と Domain Entity の分離

```
TodoEntity（DB行の形）← Room が知っている
  ↓ DataMapper
Todo（Domain Entity）← ビジネスロジックが知っている
```

```kotlin
fun TodoEntity.toDomain() = Todo(
    id = id,
    title = title,
    isCompleted = isCompleted,
    priority = TodoPriority.valueOf(priority.uppercase()),
    createdAt = createdAt,
)

fun Todo.toEntity() = TodoEntity(
    id = id, title = title, isCompleted = isCompleted,
    priority = priority.name.lowercase(), createdAt = createdAt,
)
```

sqflite での `_toRow` / `_fromRow` に相当。

#### Clean Architecture の3層

```
Presentation: TodoListScreen + TodoListViewModel
Domain:       Todo + TodoRepositoryInterface
Data:         TodoRepository + TodoLocalDataSource + TodoRemoteDataSource
```

```kotlin
// Domain Layer（Room を知らない）
interface TodoRepositoryInterface {
    fun observeAll(): Flow<List<Todo>>
    suspend fun insert(todo: Todo)
    suspend fun update(todo: Todo)
    suspend fun delete(id: String)
}

// Data Layer（Room に依存してよい）
class TodoLocalDataSource(private val dao: TodoDao) {
    fun observeAll(): Flow<List<Todo>> = dao.observeAll().map { list ->
        list.map { it.toDomain() }
    }
}
```

#### ViewModel が Notifier に相当する

```kotlin
class TodoListViewModel(
    private val repository: TodoRepositoryInterface
) : ViewModel() {

    private val _state = MutableStateFlow(TodoListState())
    val state: StateFlow<TodoListState> = _state.asStateFlow()

    init {
        // Flutter の Notifier.build() 内の _load() に相当
        viewModelScope.launch {
            repository.observeAll().collect { todos ->
                _state.update { it.copy(todos = todos, isLoading = false) }
            }
        }
    }

    fun toggle(id: String) {
        viewModelScope.launch {
            val todo = _state.value.todos.find { it.id == id } ?: return@launch
            repository.update(todo.copy(isCompleted = !todo.isCompleted))
        }
    }
}
```

**`StateFlow` と Riverpod `state` の対応**

| Riverpod | Android |
|---|---|
| `state = state.copyWith(...)` | `_state.update { it.copy(...) }` |
| `ref.watch(provider)` | `viewModel.state.collectAsState()` |
| `viewModelScope` なし（Riverpod が管理） | `viewModelScope.launch { }` |

#### 手動 DI（ViewModelProvider.Factory）

```kotlin
// Riverpod の Provider に相当
class TodoListViewModelFactory(
    private val repository: TodoRepositoryInterface
) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        return TodoListViewModel(repository) as T
    }
}

// Screen での使用
val viewModel: TodoListViewModel = viewModel(
    factory = TodoListViewModelFactory(repository)
)
```

---

## Phase 4: ナビゲーション（Navigation Compose）

### Step 8: Navigation Compose で画面遷移を実装する

#### go_router との対応

| go_router | Navigation Compose |
|---|---|
| `GoRouter(routes: [...])` | `NavHost(navController) { composable(...) }` |
| `context.go('/path')` | `navController.navigate("path") { popUpTo(0) }` |
| `context.push('/path')` | `navController.navigate("path")` |
| `context.pop()` | `navController.popBackStack()` |
| `state.pathParameters['id']` | `backStackEntry.arguments?.getString("id")` |

#### Route 定義

```kotlin
@Composable
fun AppNavGraph(
    navController: NavHostController,
    repository: TodoRepositoryInterface,
    tokenStorage: TokenStorage,
) {
    NavHost(navController, startDestination = "login") {
        composable("login") {
            LoginWebViewScreen(
                onLoginSuccess = {
                    navController.navigate("home") { popUpTo(0) }
                }
            )
        }
        composable("home") {
            TodoListScreen(
                onTodoClick = { id -> navController.navigate("todo/$id") },
                onLogout = {
                    navController.navigate("login") { popUpTo(0) }
                },
            )
        }
        composable(
            route = "todo/{id}",
            arguments = listOf(navArgument("id") { type = NavType.StringType })
        ) { backStackEntry ->
            val id = backStackEntry.arguments?.getString("id")!!
            TodoDetailScreen(todoId = id, onBack = { navController.popBackStack() })
        }
        composable(
            route = "webview?url={url}",
            arguments = listOf(navArgument("url") { type = NavType.StringType })
        ) { backStackEntry ->
            val url = backStackEntry.arguments?.getString("url") ?: ""
            WebViewScreen(url = url, onBack = { navController.popBackStack() })
        }
    }
}
```

---

### Step 9: AuthGuard（ルートガード）

go_router の `redirect` に相当する仕組みを `LaunchedEffect` + `authState` で実装する。

```kotlin
// AppNavGraph 内
val authState by authViewModel.state.collectAsState()

LaunchedEffect(authState.isLoggedIn, navController) {
    val currentRoute = navController.currentBackStackEntry?.destination?.route
    if (!authState.isLoggedIn && currentRoute != "login") {
        navController.navigate("login") { popUpTo(0) }
    }
    if (authState.isLoggedIn && currentRoute == "login") {
        navController.navigate("home") { popUpTo(0) }
    }
}
```

`LaunchedEffect` は `authState` が変わるたびに再実行される。  
go_router の `refreshListenable` + `redirect` の組み合わせに相当する。

---

## Phase 5: API連携（Ktor Client）

### Step 10: Ktor Client で API 通信 + DataSource 分離

#### なぜ Ktor Client か

| | Retrofit | Ktor Client |
|---|---|---|
| API 定義 | アノテーション（`@GET`） | コードで記述（型安全） |
| Kotlin coroutines | 対応 | ネイティブ対応（suspend fun） |
| Multiplatform | 非対応 | 対応（将来 KMP に移行しやすい） |
| インターセプター | `Interceptor` | `HttpSend` Plugin |

Ktor は Kotlin ネイティブ設計で、coroutines との親和性が高い。

#### Ktor Client の基本

```kotlin
val client = HttpClient(Android) {
    install(ContentNegotiation) {
        json(Json { ignoreUnknownKeys = true })
    }
    defaultRequest {
        url("https://jsonplaceholder.typicode.com")
        // 認証ヘッダーはここで付与
        // header("Authorization", "Bearer $token")
    }
}

// GET /todos （suspend fun）
val dtos: List<TodoDto> = client.get("/todos") {
    parameter("_limit", 20)
}.body()
```

`dio` の `BaseOptions(baseUrl: ...)` + インターセプターに相当。

#### DTO と DataMapper

```kotlin
// API レスポンスの形（JSONPlaceholder）
@Serializable
data class TodoDto(
    val id: Int,
    val title: String,
    val completed: Boolean,
)

// DTO → Domain Entity
fun TodoDto.toEntity() = Todo(
    id = "api_$id",
    title = title,
    isCompleted = completed,
    description = "APIから取得",
    priority = TodoPriority.MEDIUM,
    createdAt = System.currentTimeMillis(),
)
```

Flutter 版の `TodoDto.toEntity()` と同一パターン。

#### DataSource 分離

```
TodoRepository（調停役）
  ├── TodoLocalDataSource  ← Room
  └── TodoRemoteDataSource ← Ktor Client
```

```kotlin
class TodoRepository(
    private val local: TodoLocalDataSource,
    private val remote: TodoRemoteDataSource,
) : TodoRepositoryInterface {

    override suspend fun sync() {
        val dtos = remote.fetchAll()
        val existing = local.findAllIds()
        dtos.filter { it.id !in existing }  // 重複スキップ
            .forEach { local.insert(it.toEntity()) }
    }
}
```

---

## Phase 6: WebView

### Step 11: AndroidView で WebView を表示する

#### なぜ AndroidView が必要か

Jetpack Compose は自前の描画エンジンを持つため、Android の従来 View（WebView）を直接使えない。  
`AndroidView` はその橋渡し役。Flutter の `webview_flutter` が `WKWebView` / `WebView` をラップするのと同じ構造。

```kotlin
@Composable
fun WebViewScreen(url: String) {
    var isLoading by remember { mutableStateOf(true) }
    val webViewRef = remember { mutableStateOf<WebView?>(null) }

    Box {
        AndroidView(
            factory = { context ->
                WebView(context).apply {
                    settings.javaScriptEnabled = true
                    webViewClient = object : WebViewClient() {
                        override fun onPageFinished(view: WebView, url: String) {
                            isLoading = false
                        }
                    }
                    loadUrl(url)
                }.also { webViewRef.value = it }
            },
            modifier = Modifier.fillMaxSize()
        )
        if (isLoading) {
            CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
        }
    }
}
```

`_isLoading` を `remember { mutableStateOf(true) }` で持つのは、Flutter でローカル状態を `StatefulWidget` に持たせたのと同じ判断。

---

### Step 12: ホワイトリスト制御

#### shouldOverrideUrlLoading でブロック

```kotlin
webViewClient = object : WebViewClient() {
    override fun shouldOverrideUrlLoading(
        view: WebView,
        request: WebResourceRequest,
    ): Boolean {
        val host = request.url.host ?: return true  // nullはブロック
        if (WebViewConfig.isAllowed(host)) return false  // 許可 → WebView で開く

        // ブロック → Custom Tabs で外部に渡す
        CustomTabsIntent.Builder().build().launchUrl(context, request.url)
        return true  // WebView での遷移はキャンセル
    }
}
```

Flutter の `NavigationDelegate.onNavigationRequest` に相当。戻り値の意味が逆（`false` = 許可）なので注意。

---

## Phase 7: 認証

### Step 13: ログイン画面（WebView + JavaScript Interface）

#### `@JavascriptInterface` アノテーション

Flutter の `JavaScriptChannel` に相当するが、クラスのメソッドに直接アノテーションをつける。

```kotlin
inner class FlutterAuthBridge {
    @JavascriptInterface  // ← このメソッドが JS から呼べる
    fun postMessage(json: String) {
        // WebView の JS スレッドから呼ばれる → メインスレッドへ切り替え
        mainScope.launch { onAuthMessage(json) }
    }
}

// WebView に登録（グローバル JS オブジェクト "FlutterAuth" になる）
webView.addJavascriptInterface(FlutterAuthBridge(), "FlutterAuth")
```

HTML 側の呼び出しは Flutter 版と同一:
```javascript
FlutterAuth.postMessage(JSON.stringify({ token: "mock_token" }));
```

**セキュリティ注意**: `@JavascriptInterface` は API 17 以上では `public` かつアノテーション付きのメソッドだけが JS に公開される。ホワイトリスト制御（Step 12）で外部ページへの遷移をブロックすることが前提。

#### `ConsumerStatefulWidget` に相当するパターン

Flutter で `ConsumerStatefulWidget` を使ったのと同じ理由（ViewModel アクセス + 従来 View のライフサイクル）で、AndroidView と ViewModel を組み合わせる。

```kotlin
@Composable
fun LoginWebViewScreen(
    viewModel: AuthViewModel = viewModel(),
    onLoginSuccess: () -> Unit,
) {
    val authState by viewModel.state.collectAsState()
    LaunchedEffect(authState.isLoggedIn) {
        if (authState.isLoggedIn) onLoginSuccess()
    }

    AndroidView(factory = { context ->
        WebView(context).apply {
            addJavascriptInterface(
                FlutterAuthBridge { token -> viewModel.loginWithToken(token) },
                "FlutterAuth"
            )
            loadUrl("file:///android_asset/login.html")
        }
    })
}
```

---

### Step 14: EncryptedSharedPreferences でトークン管理

#### SharedPreferences vs EncryptedSharedPreferences

| | SharedPreferences | EncryptedSharedPreferences |
|---|---|---|
| 保存場所 | ファイル（平文） | ファイル（AES暗号化） |
| キー管理 | なし | Android Keystore |
| 用途 | テーマ・言語設定 | 認証トークン |

`flutter_secure_storage` の Android 側の実装がまさにこれ。

#### TokenStorage を手動 DI で管理

```kotlin
// Flutter の tokenStorageProvider に相当
class TokenStorage(private val context: Context) {
    private val prefs: SharedPreferences by lazy {
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
        EncryptedSharedPreferences.create(
            context, "secure_prefs", masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
        )
    }

    fun read(): String? = prefs.getString("auth_token", null)
    fun write(token: String) = prefs.edit().putString("auth_token", token).apply()
    fun delete() = prefs.edit().remove("auth_token").apply()
}
```

#### AuthViewModel.init でトークン確認（自動ログイン）

```kotlin
// Flutter の AsyncNotifier.build() に相当
class AuthViewModel(private val tokenStorage: TokenStorage) : ViewModel() {
    private val _state = MutableStateFlow(AuthState())
    val state: StateFlow<AuthState> = _state.asStateFlow()

    init {
        // アプリ起動時にトークンを確認
        val token = tokenStorage.read()
        _state.update { it.copy(isLoggedIn = token != null, token = token) }
    }

    fun loginWithToken(token: String) {
        tokenStorage.write(token)
        _state.update { it.copy(isLoggedIn = true, token = token) }
    }

    fun logout() {
        tokenStorage.delete()
        _state.update { it.copy(isLoggedIn = false, token = null) }
    }
}
```

---

### Step 15: OAuth フロー（Chrome Custom Tabs）

#### なぜ WebView で OAuth をやってはいけないか

Flutter 版 Step 15 と同じ理由（RFC 8252 準拠）。  
Android での外部ブラウザ起動は `ASWebAuthenticationSession` の代わりに Chrome Custom Tabs を使う。

#### Chrome Custom Tabs で認可 URL を開く

```kotlin
// flutter_web_auth_2 の Android 側の実装そのもの
val intent = CustomTabsIntent.Builder()
    .setShowTitle(true)
    .build()
intent.launchUrl(context, Uri.parse(authorizationUrl))
```

#### Intent filter でコールバックを受け取る

```xml
<!-- AndroidManifest.xml -->
<activity android:name=".MainActivity" ...>
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="todoapp" android:host="callback" />
    </intent-filter>
</activity>
```

`todoapp://callback?code=xxx` という URL でブラウザからアプリに戻る。  
Flutter の `CFBundleURLTypes` に相当する設定。

#### JS Bridge との連携

OAuth ボタンは `login.html` に置く（Flutter 版と同じ HTML ファイルを流用できる）。

```javascript
// login.html（Flutter 版と共通）
function handleOAuth() {
    FlutterAuth.postMessage(JSON.stringify({ type: 'oauth' }));
}
```

```kotlin
// FlutterAuthBridge
@JavascriptInterface
fun postMessage(json: String) {
    val data = JSONObject(json)
    when (data.getString("type")) {
        "oauth" -> mainScope.launch { startOAuthFlow() }
        else    -> mainScope.launch { loginWithToken(data.getString("token")) }
    }
}
```

#### `onNewIntent` でコールバックを処理

Custom Tabs からアプリに戻ると `MainActivity.onNewIntent` が呼ばれる。

```kotlin
// MainActivity.kt
override fun onNewIntent(intent: Intent) {
    super.onNewIntent(intent)
    val uri = intent.data ?: return
    if (uri.scheme == "todoapp" && uri.host == "callback") {
        val code = uri.getQueryParameter("code")
        // ViewModel にコードを渡してトークン取得
        authViewModel.handleOAuthCallback(code)
    }
}
```

---

## セットアップメモ

- プロジェクト: `android_compose/` （Android Studio で Empty Activity / Compose）
- エミュレーター: Pixel 9 API 36（`emulator-5554`）
- minSdk: 26（EncryptedSharedPreferences の要件）
- Kotlin: 最新安定版
- Compose BOM: 最新安定版
