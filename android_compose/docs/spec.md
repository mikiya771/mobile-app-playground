# Android Compose 個別仕様

共通仕様は `docs/spec.md`（ルート）を参照。ここには Android Compose 固有の技術選定を記載する。

---

## 採用技術スタック

| 役割 | 技術 |
|------|------|
| 言語 | Kotlin |
| UI | Jetpack Compose + Material3 |
| ナビゲーション | Navigation Compose |
| 状態管理 | ViewModel + StateFlow |
| DI | 手動 DI（ViewModelProvider.Factory） |
| 永続化 | Room |
| HTTP クライアント | Ktor Client |
| WebView | AndroidView(WebView) |
| セキュアストレージ | EncryptedSharedPreferences（Jetpack Security） |
| OAuth | Chrome Custom Tabs + Intent filter |

> **DI について**: Hilt が Android 標準だが、学習目的のため手動 DI（Factory パターン）で透明性を優先する。  
> Flutter 版での Riverpod Provider との対応: `ViewModelProvider.Factory` が DIコンテナの役割を担う。

---

## Flutter との技術対応表

| Flutter | Android Compose |
|---------|----------------|
| `@Composable` に相当するのは `Widget` + `build()` | `@Composable` 関数 |
| `StatelessWidget` | stateless `@Composable` |
| `StatefulWidget` + `setState` | `remember { mutableStateOf() }` |
| `Column` / `Row` / `Container` | `Column` / `Row` / `Box` + `Modifier` |
| `Riverpod Notifier` | `ViewModel` + `StateFlow` |
| `ref.watch(provider)` | `collectAsState()` |
| `go_router` | Navigation Compose（`NavController`） |
| `sqflite` | Room |
| `dio` | Ktor Client |
| `webview_flutter` | `AndroidView { WebView(...) }` |
| `flutter_secure_storage` | `EncryptedSharedPreferences` |
| `flutter_web_auth_2` | Chrome Custom Tabs + Intent filter |

---

## アーキテクチャ方針

### Clean Architecture の3層

```
Presentation Layer  Composable（View）/ ViewModel
Domain Layer        Entity（Todo）/ Repository Interface
Data Layer          Repository 実装（Room + Ktor）
```

依存の向きは **外 → 内**。Presentation は Domain を知っているが Domain は Presentation を知らない。

### データフローの原則

```
ViewModel（StateFlow<State>）
  ↓ collectAsState()
Composable（状態を受け取って描画）
  ↓ イベント（コールバック / lambda）
ViewModel（状態を更新）
```

Flutter の「ref.watch → Notifier → state」と同じ一方向データフロー。

### ViewModel と Notifier の対応

```kotlin
// Android Compose
class TodoListViewModel(
    private val repository: TodoRepositoryInterface
) : ViewModel() {
    private val _state = MutableStateFlow(TodoListState())
    val state: StateFlow<TodoListState> = _state.asStateFlow()

    fun toggle(id: String) {
        viewModelScope.launch {
            // リポジトリ更新 → state 更新
        }
    }
}
```

```dart
// Flutter 版（対応）
class TodoListNotifier extends Notifier<TodoListState> {
    @override
    TodoListState build() { ... }
    Future<void> toggle(String id) async { ... }
}
```

### State は data class（イミュータブル）

```kotlin
data class TodoListState(
    val todos: List<Todo> = emptyList(),
    val filter: TodoFilter = TodoFilter.ALL,
    val isLoading: Boolean = true,
)
```

`state = state.copy(todos = ...)` で新しいインスタンスを代入。Kotlin の `data class` は `copyWith` を `copy` として自動生成する。

---

## ディレクトリ構成

```
android_compose/app/src/main/java/com/example/todoapp/
  config/
    WebViewConfig.kt              ← ホワイトリスト定数
  features/
    auth/
      AuthViewModel.kt
      TokenStorage.kt
      screens/
        LoginWebViewScreen.kt
    todo/
      Todo.kt                     ← Entity
      TodoRepositoryInterface.kt
      TodoRepository.kt
      TodoListViewModel.kt
      data/
        local/
          TodoLocalDataSource.kt
          TodoDao.kt
          TodoDatabase.kt
          TodoEntity.kt           ← Room Entity（DB行の型）
        remote/
          TodoRemoteDataSource.kt
          TodoDto.kt
      screens/
        TodoListScreen.kt
        TodoDetailScreen.kt
        TodoFormScreen.kt
      components/
        FilterTabBar.kt
        PriorityBadge.kt
        TodoCard.kt
    webview/
      screens/
        WebViewScreen.kt
  navigation/
    AppNavGraph.kt                ← NavHost 定義（router.dart 相当）
  MainActivity.kt
```

---

## ナビゲーション（Navigation Compose）

### ルート定義

```kotlin
// go_router との対応
// GoRoute(path: '/') → composable("home") { TodoListScreen(...) }
// GoRoute(path: '/todos/:id') → composable("todo/{id}") { ... }

NavHost(navController, startDestination = "login") {
    composable("login")       { LoginWebViewScreen(...) }
    composable("home")        { TodoListScreen(...) }
    composable("todo/{id}")   { TodoDetailScreen(id = it.arguments?.getString("id")!!) }
    composable("webview?url={url}") { WebViewScreen(...) }
}
```

### AuthGuard

go_router の `redirect` に相当する仕組みを `NavController.addOnDestinationChangedListener` + `AuthViewModel` の StateFlow で実装する。

```kotlin
LaunchedEffect(authState) {
    if (!authState.isLoggedIn && currentRoute != "login") {
        navController.navigate("login") { popUpTo(0) }
    }
}
```

---

## WebView（AndroidView）

Compose には WebView ウィジェットが存在しないため `AndroidView` でラップして使う。

```kotlin
AndroidView(
    factory = { context ->
        WebView(context).apply {
            settings.javaScriptEnabled = true
            webViewClient = object : WebViewClient() {
                override fun shouldOverrideUrlLoading(
                    view: WebView, request: WebResourceRequest
                ): Boolean {
                    // ホワイトリスト制御（Step 12）
                    return !WebViewConfig.isAllowed(request.url.host ?: "")
                }
            }
        }
    },
    update = { webView -> webView.loadUrl(url) }
)
```

---

## JS Bridge（JavaScript Interface）

Flutter の `JavaScriptChannel` に相当する仕組み。

```kotlin
// Flutter: controller.addJavaScriptChannel('FlutterAuth', ...)
// Android:
inner class FlutterAuthBridge {
    @JavascriptInterface
    fun postMessage(json: String) {
        // WebView スレッドで呼ばれる → MainThread に切り替えが必要
        mainScope.launch { onMessageReceived(json) }
    }
}
webView.addJavascriptInterface(FlutterAuthBridge(), "FlutterAuth")
```

HTML 側の呼び出しは Flutter 版と同一。

---

## セキュアストレージ（EncryptedSharedPreferences）

```kotlin
val masterKey = MasterKey.Builder(context)
    .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
    .build()

val prefs = EncryptedSharedPreferences.create(
    context,
    "secure_prefs",
    masterKey,
    EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
    EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
)

prefs.edit().putString("auth_token", token).apply()
val token = prefs.getString("auth_token", null)
```

Keystore にマスターキーを置き、SharedPreferences の内容を AES で暗号化する。iOS の Keychain に相当。

---

## OAuth（Chrome Custom Tabs）

```kotlin
// flutter_web_auth_2 の Android 側の実装そのもの
val intent = CustomTabsIntent.Builder().build()
intent.launchUrl(context, Uri.parse(authUrl))

// コールバック受信: AndroidManifest.xml に Intent filter を登録
// <intent-filter>
//   <action android:name="android.intent.action.VIEW" />
//   <category android:name="android.intent.category.DEFAULT" />
//   <category android:name="android.intent.category.BROWSABLE" />
//   <data android:scheme="todoapp" android:host="callback" />
// </intent-filter>
```

---

## Room スキーマ

共通仕様の SQLite スキーマを Room Entity で表現する。

```kotlin
@Entity(tableName = "todos")
data class TodoEntity(
    @PrimaryKey val id: String,
    val title: String,
    val description: String = "",
    val isCompleted: Boolean = false,
    val priority: String = "medium",
    val createdAt: Long,  // エポックミリ秒
)
```

---

## Ktor Client 設定

```kotlin
val client = HttpClient(Android) {
    install(ContentNegotiation) {
        json(Json { ignoreUnknownKeys = true })
    }
    defaultRequest {
        url("https://jsonplaceholder.typicode.com")
    }
}

// GET /todos
val dtos: List<TodoDto> = client.get("/todos") {
    parameter("_limit", 20)
}.body()
```

`dio` の `BaseOptions(baseUrl: ...)` + `Interceptor` に相当。認証ヘッダーは `defaultRequest` ブロックで付与できる。
