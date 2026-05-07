# Android XML 学習ノート（読み物）

外出先でも読める概念まとめ。手を動かす課題は `exercises.md` を参照。

---

## 進捗

- [x] Step 1: Activity と ViewBinding を読む
- [x] Step 2: RecyclerView + ListAdapter を実装する
- [x] Step 3: ConstraintLayout でレイアウトを組む
- [ ] Step 4: モデルクラス Todo を作る
- [ ] Step 5 & 6: インタラクションを追加する (ViewModel + LiveData)
- [ ] Step 7: Room で CRUD を実装する / ViewModel + MVVM + Clean Architecture 導入
- [ ] Step 8: NavGraph XML で画面遷移を実装する（Navigation Component）
- [ ] Step 9: AuthGuard を追加する
- [ ] Step 10: Retrofit で JSONPlaceholder から Todo を取得・同期する
- [ ] Step 11: WebView を実装する
- [ ] Step 12: ホワイトリスト制御を実装する
- [ ] Step 13: ログイン画面（WebView + JavaScript Interface）
- [ ] Step 14: EncryptedSharedPreferences でトークン管理・AuthGuard
- [ ] Step 15: OAuth フロー（Chrome Custom Tabs）

---

## Compose 版との根本的な違い

| 概念 | Compose | XML |
|---|---|---|
| UI 記述 | Kotlin コード（関数） | XML ファイル |
| 状態更新 | 再コンポーズ（関数の再実行） | View の setter (`text = ...`) |
| リスト | `LazyColumn` | `RecyclerView` + `Adapter` |
| 状態保持 | `remember { mutableStateOf() }` | `LiveData` / `ViewModel` |
| 画面遷移 | `NavHostController` (コード) | `NavController` (XML navgraph) |
| DI | 手動 Factory / Hilt | 手動 Factory / Hilt |

---

## Phase 1: XML 基礎

### Step 1: Activity と ViewBinding

**`setContentView` から ViewBinding へ**

```kotlin
// 旧来の書き方（型安全でない）
setContentView(R.layout.activity_main)
val textView = findViewById<TextView>(R.id.textView)

// ViewBinding（型安全 + null安全）
private lateinit var binding: ActivityMainBinding
binding = ActivityMainBinding.inflate(layoutInflater)
setContentView(binding.root)
binding.textView.text = "Hello"
```

ViewBinding は Compose の `MaterialTheme.colorScheme.primary` を型安全に参照するのと同じ目的（コンパイル時エラー検出）を達成する。

**XML レイアウトの構造**

```xml
<!-- activity_main.xml -->
<LinearLayout ...>          <!-- Compose の Column に相当 -->
    <TextView ... />        <!-- Compose の Text に相当 -->
    <RecyclerView ... />    <!-- Compose の LazyColumn に相当 -->
</LinearLayout>
```

---

### Step 2: RecyclerView + ListAdapter

**RecyclerView は LazyColumn より低レベルな API**

Compose の `LazyColumn` は内部で RecyclerView 相当の仕組みを持つが、Adapter パターンを隠蔽している。XML では Adapter を自分で書く必要がある。

```
RecyclerView（表示の枠組み）
  └── ListAdapter<Todo, TodoViewHolder>（データとViewの仲介）
        ├── DiffUtil.ItemCallback（差分計算）
        └── TodoViewHolder（1行分のView）
```

**DiffUtil で効率的な差分更新**

```kotlin
// DiffUtil.ItemCallback で新旧リストを比較
val DIFF = object : DiffUtil.ItemCallback<Todo>() {
    // 同じアイテムか（IDで判定）
    override fun areItemsTheSame(old: Todo, new: Todo) = old.id == new.id
    // 内容が同じか（equals で判定）
    override fun areContentsTheSame(old: Todo, new: Todo) = old == new
}
```

Compose の `LazyColumn { items(todos, key = { it.id }) }` が自動で行う差分検出を、XMLでは明示的に書く。

**ViewHolder パターン**

```kotlin
class TodoViewHolder(private val binding: ItemTodoBinding) :
    RecyclerView.ViewHolder(binding.root) {

    fun bind(todo: Todo) {
        binding.titleText.text = todo.title
        binding.checkIcon.isActivated = todo.isCompleted
    }
}
```

Flutter の Widget build() がイミュータブルな Widget を返すのと対照的に、ViewHolder は View を再利用・更新する。

---

### Step 3: ConstraintLayout でレイアウトを組む

**Compose の `Modifier.weight(1f)` に相当するもの**

```xml
<!-- ConstraintLayout で横幅を分割 -->
<TextView
    android:id="@+id/tabAll"
    app:layout_constraintWidth_percent="0.33"
    app:layout_constraintStart_toStartOf="parent" />
```

または `LinearLayout` の `layout_weight`:

```xml
<LinearLayout android:orientation="horizontal">
    <Button android:layout_weight="1" ... /> <!-- Modifier.weight(1f) に相当 -->
    <Button android:layout_weight="1" ... />
    <Button android:layout_weight="1" ... />
</LinearLayout>
```

**Flutter との対応**

| Flutter | Android XML |
|---|---|
| `Column` | `LinearLayout(orientation=vertical)` |
| `Row` | `LinearLayout(orientation=horizontal)` |
| `Stack` | `FrameLayout` / `ConstraintLayout` |
| `Expanded` | `layout_weight="1"` |
| `Padding` | `padding` / `margin` |
| `Card` | `MaterialCardView` |

---

## Phase 2: TODO 一覧画面（UI だけ）

### Step 4: モデルクラス Todo

Compose 版と同一。Kotlin `data class` + `enum class` の組み合わせ。

```kotlin
data class Todo(
    val id: String,
    val title: String,
    val description: String = "",
    val isCompleted: Boolean = false,
    val priority: TodoPriority = TodoPriority.MEDIUM,
    val createdAt: Long = System.currentTimeMillis(),
)

enum class TodoPriority { LOW, MEDIUM, HIGH }
enum class TodoFilter { ALL, ACTIVE, COMPLETED }
```

`copy()` は `data class` が自動生成する（Flutter では手書きの `copyWith()` に相当）。

---

### Step 5 & 6: インタラクションと ViewModel + LiveData

**Compose の `remember { mutableStateOf() }` に相当するもの**

```kotlin
// Compose
var todos by remember { mutableStateOf(dummyTodos) }

// XML + ViewModel + LiveData
class TodoListViewModel : ViewModel() {
    private val _todos = MutableLiveData<List<Todo>>(emptyList())
    val todos: LiveData<List<Todo>> = _todos
}

// Fragment で監視
viewModel.todos.observe(viewLifecycleOwner) { todos ->
    adapter.submitList(todos)  // ListAdapter が差分更新
}
```

**LiveData と StateFlow の違い**

| | LiveData | StateFlow |
|---|---|---|
| ライフサイクル自動管理 | ✅（observe に viewLifecycleOwner を渡す） | ❌（repeatOnLifecycle が必要） |
| Compose 対応 | `collectAsStateWithLifecycle()` | ✅ネイティブ |
| XML 対応 | ✅ネイティブ | 追加処理が必要 |

XML + Fragment では LiveData が自然。Compose では StateFlow が自然。

---

## Phase 3: 永続化（Room）

### Step 7: Room + ViewModel + MVVM

Compose 版と同一の構造。Entity / Dao / Database / DataSource / Repository / ViewModel の6層。

**LiveData を Flow の代わりに使う場合**

```kotlin
@Dao
interface TodoDao {
    @Query("SELECT * FROM todos ORDER BY createdAt DESC")
    fun observeAll(): LiveData<List<TodoEntity>>  // Flow の代わりに LiveData も可
}
```

Repository でも LiveData → liveData { } ビルダーで変換できる。

---

## Phase 4: ナビゲーション（Navigation Component）

### Step 8: NavGraph XML で画面遷移を実装する

**go_router / Navigation Compose との対応**

| go_router | Navigation Compose | Navigation Component (XML) |
|---|---|---|
| `GoRoute(path: '/home')` | `composable("home") { }` | `<fragment android:id="@+id/homeFragment" />` |
| `context.go('/path')` | `navController.navigate("path")` | `navController.navigate(R.id.action_xxx)` |
| `context.pop()` | `navController.popBackStack()` | `navController.popBackStack()` |

**NavGraph XML の例**

```xml
<!-- res/navigation/nav_graph.xml -->
<navigation android:startDestination="@id/loginFragment">
    <fragment android:id="@+id/loginFragment"
              android:name=".auth.LoginFragment">
        <action android:id="@+id/action_login_to_home"
                app:destination="@id/todoListFragment"
                app:popUpTo="@id/loginFragment"
                app:popUpToInclusive="true" />
    </fragment>
    <fragment android:id="@+id/todoListFragment"
              android:name=".features.todo.TodoListFragment">
        <action android:id="@+id/action_list_to_detail"
                app:destination="@id/todoDetailFragment" />
    </fragment>
</navigation>
```

**FragmentContainerView で NavHost を配置**

```xml
<androidx.fragment.app.FragmentContainerView
    android:id="@+id/nav_host_fragment"
    app:navGraph="@navigation/nav_graph"
    app:defaultNavHost="true" />
```

---

### Step 9: AuthGuard

**Navigation Component では `NavController.addOnDestinationChangedListener` でガード**

```kotlin
navController.addOnDestinationChangedListener { _, destination, _ ->
    if (!authViewModel.state.value.isLoggedIn &&
        destination.id != R.id.loginFragment) {
        navController.navigate(R.id.loginFragment) {
            popUpTo(0)
        }
    }
}
```

Compose 版の `LaunchedEffect(authState.isLoggedIn)` に相当する仕組み。

---

## Phase 5: API 連携（Retrofit）

### Step 10: Retrofit + JSONPlaceholder

**Ktor Client との対応**

| Ktor Client | Retrofit |
|---|---|
| `client.get("/todos") { ... }.body<List<TodoDto>>()` | `@GET("/todos") suspend fun fetchAll(): List<TodoDto>` |
| `defaultRequest { url("...") }` | `Retrofit.Builder().baseUrl("...")` |
| `install(ContentNegotiation) { json(...) }` | `addConverterFactory(GsonConverterFactory.create())` |

```kotlin
interface TodoApiService {
    @GET("todos")
    suspend fun fetchTodos(@Query("_limit") limit: Int = 20): List<TodoDto>
}

val retrofit = Retrofit.Builder()
    .baseUrl("https://jsonplaceholder.typicode.com/")
    .addConverterFactory(GsonConverterFactory.create())
    .build()

val service = retrofit.create(TodoApiService::class.java)
```

---

## Phase 6: WebView

### Step 11: WebView

XML では `WebView` を直接レイアウトに配置できる（Compose の `AndroidView` ラッパーが不要）。

```xml
<WebView
    android:id="@+id/webView"
    android:layout_width="match_parent"
    android:layout_height="match_parent" />
```

```kotlin
binding.webView.apply {
    settings.javaScriptEnabled = true
    webViewClient = object : WebViewClient() {
        override fun onPageFinished(view: WebView, url: String) {
            binding.progressBar.visibility = View.GONE
        }
    }
    loadUrl(url)
}
```

Compose 版と比べて `AndroidView { }` のラッパーが不要な分シンプル。ただし ViewBinding で binding.root にアクセスしてから操作する手順は同じ。

---

### Step 12: ホワイトリスト制御

Compose 版と同一ロジック。`shouldOverrideUrlLoading` でホワイトリスト外を Chrome Custom Tabs に渡す。

---

## Phase 7: 認証

### Step 13: WebView + JavaScript Interface

Compose 版と同一ロジック。`@JavascriptInterface` アノテーション + `addJavascriptInterface()`。

XML 版では Fragment のライフサイクルに注意：

```kotlin
// Fragment が破棄されたときに WebView をクリーンアップ
override fun onDestroyView() {
    binding.webView.removeJavascriptInterface("FlutterAuth")
    super.onDestroyView()
    _binding = null
}
```

---

### Step 14: EncryptedSharedPreferences

Compose 版と同一。`TokenStorage` クラスを共有できる構造。

---

### Step 15: OAuth フロー（Chrome Custom Tabs）

Compose 版と同一フロー。`onNewIntent` の受け取りは `MainActivity` で行う点も同じ。

---

## セットアップメモ

- プロジェクト: `android_xml/`（Android Studio で Empty Views Activity）
- エミュレーター: Pixel 9 API 36
- minSdk: 26
- Kotlin: 2.0.21
- AGP: 8.13.2
