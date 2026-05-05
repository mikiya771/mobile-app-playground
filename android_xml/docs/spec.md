# Android XML（Fragment + RecyclerView）実装仕様

共通仕様: `docs/spec.md` を参照。
本ファイルはAndroid XML / Fragment固有の技術選定・構成を記載する。

---

## 技術スタック

| レイヤー | 技術 |
|---|---|
| 状態管理 | ViewModel + LiveData |
| ナビゲーション | Navigation Component（Fragment） |
| ローカルDB | Room（SQLite） |
| API通信 | Retrofit + Gson |
| WebView（詳細・ログイン） | WebView（XMLレイアウト） |
| OAuth | Custom Tabs（androidx.browser） |
| セキュアストレージ | EncryptedSharedPreferences |
| リスト | RecyclerView + ListAdapter + DiffUtil |
| View binding | ViewBinding |
| 最低SDK | 26（Android 8.0） |

---

## ディレクトリ構成

```
com/example/todoxml/
├── TodoApplication.kt
├── MainActivity.kt              # NavHostFragment のホスト
├── config/
│   └── AppConfig.kt
├── data/
│   ├── model/Todo.kt            # @Entity（Compose版と共通構造）
│   ├── db/TodoDao.kt + TodoDatabase.kt
│   ├── api/TodoApiService.kt
│   └── repository/
│       ├── TodoRepository.kt
│       └── AuthRepository.kt
├── ui/
│   ├── viewmodel/
│   │   ├── AuthViewModel.kt
│   │   └── TodoViewModel.kt
│   ├── fragments/
│   │   ├── LoginFragment.kt
│   │   ├── LoginWebViewFragment.kt
│   │   ├── TodoListFragment.kt
│   │   ├── TodoDetailWebViewFragment.kt
│   │   └── TodoFormFragment.kt
│   └── adapters/
│       └── TodoAdapter.kt       # ListAdapter + DiffUtil.ItemCallback

res/
├── layout/
│   ├── activity_main.xml        # NavHostFragment
│   ├── fragment_login.xml
│   ├── fragment_login_webview.xml
│   ├── fragment_todo_list.xml   # RecyclerView + FAB
│   ├── fragment_todo_detail_webview.xml
│   ├── fragment_todo_form.xml
│   └── item_todo.xml            # RecyclerViewの行レイアウト
├── navigation/
│   └── nav_graph.xml            # AuthGuard: LoginFragment / Main NavGraph分離
└── values/
    ├── strings.xml
    └── themes.xml
```

---

## Compose版との主な差異

| 観点 | Compose | XML |
|---|---|---|
| UI定義 | Kotlin関数（@Composable） | XMLレイアウト + ViewBinding |
| リスト | LazyColumn | RecyclerView + ListAdapter |
| 状態 | StateFlow + collectAsState | LiveData + observe |
| ナビゲーション | NavHost（コード） | nav_graph.xml（リソース） |
| WebView | AndroidView ラッパー | XMLに直接配置 |

---

## 主要実装ポイント

### AuthGuard（nav_graph.xml）

```xml
<!-- ログイン前グラフ -->
<navigation android:id="@+id/auth_graph"
            app:startDestination="@id/loginFragment">
    <fragment android:id="@+id/loginFragment" ... />
    <fragment android:id="@+id/loginWebViewFragment" ... />
</navigation>

<!-- メイングラフ -->
<navigation android:id="@+id/main_graph"
            app:startDestination="@id/todoListFragment">
    ...
</navigation>
```

`MainActivity` でトークン有無を確認し、起動時に表示するグラフを切り替える。

### JS Bridge受信（LoginWebViewFragment）

```kotlin
binding.webView.addJavascriptInterface(object {
    @JavascriptInterface
    fun onAuthSuccess(token: String) {
        requireActivity().runOnUiThread {
            authViewModel.login(token)
        }
    }
}, "AuthBridgeInterface")
binding.webView.loadUrl("file:///android_asset/login.html")
```

### RecyclerView + ListAdapter

```kotlin
class TodoAdapter(
    private val onToggle: (Todo) -> Unit,
    private val onClick: (Todo) -> Unit,
) : ListAdapter<Todo, TodoAdapter.ViewHolder>(DiffCallback()) {

    class DiffCallback : DiffUtil.ItemCallback<Todo>() {
        override fun areItemsTheSame(old: Todo, new: Todo) = old.id == new.id
        override fun areContentsTheSame(old: Todo, new: Todo) = old == new
    }
    ...
}
```

### WebViewホワイトリスト制御

Compose版と同じ `WebViewClient.shouldOverrideUrlLoading` パターンを使用。

---

## build.gradle 主要依存

Compose版と共通。加えて:

```kotlin
// Navigation Fragment
implementation("androidx.navigation:navigation-fragment-ktx:2.7.6")
implementation("androidx.navigation:navigation-ui-ktx:2.7.6")

// ViewBinding は android {} ブロックで有効化
buildFeatures { viewBinding = true }
```
