# Android Jetpack Compose 実装仕様

共通仕様: `docs/spec.md` を参照。
本ファイルはAndroid Jetpack Compose固有の技術選定・構成を記載する。

---

## 技術スタック

| レイヤー | 技術 |
|---|---|
| 状態管理 | ViewModel + StateFlow |
| ナビゲーション | Navigation Compose |
| ローカルDB | Room（SQLite） |
| API通信 | Retrofit + Gson |
| WebView（詳細・ログイン） | AndroidView（WebView） |
| OAuth | Custom Tabs（androidx.browser） |
| セキュアストレージ | EncryptedSharedPreferences |
| 最低SDK | 26（Android 8.0） |
| Kotlin | 1.9+ |

---

## ディレクトリ構成

```
com/example/todocompose/
├── TodoApplication.kt           # Hilt / DI設定（任意）
├── MainActivity.kt              # NavHost のホスト
├── config/
│   └── AppConfig.kt             # allowedHosts, baseUrl, URLスキーム
├── data/
│   ├── model/
│   │   └── Todo.kt              # @Entity（Room）
│   ├── db/
│   │   ├── TodoDao.kt
│   │   └── TodoDatabase.kt
│   ├── api/
│   │   └── TodoApiService.kt    # Retrofit interface
│   └── repository/
│       ├── TodoRepository.kt
│       └── AuthRepository.kt    # EncryptedSharedPreferences操作
├── ui/
│   ├── viewmodel/
│   │   ├── AuthViewModel.kt
│   │   └── TodoViewModel.kt
│   └── screens/
│       ├── LoginScreen.kt
│       ├── LoginWebViewScreen.kt  # JavascriptInterface
│       ├── TodoListScreen.kt
│       ├── TodoDetailWebViewScreen.kt
│       └── TodoFormScreen.kt
└── navigation/
    └── NavGraph.kt              # AuthGuard付きNavHost
```

---

## 主要実装ポイント

### AuthGuard（NavGraph）

```kotlin
composable("list") {
    val token by authVM.token.collectAsState()
    LaunchedEffect(token) {
        if (token == null) navController.navigate("login") {
            popUpTo(0) { inclusive = true }
        }
    }
    TodoListScreen(...)
}
```

### JS Bridge受信（LoginWebViewScreen）

```kotlin
AndroidView(factory = { ctx ->
    WebView(ctx).apply {
        settings.javaScriptEnabled = true
        addJavascriptInterface(object {
            @JavascriptInterface
            fun onAuthSuccess(token: String) {
                authVM.login(token)
            }
        }, "AuthBridgeInterface")
        loadUrl("file:///android_asset/login.html")
    }
})
```

### WebViewホワイトリスト制御

```kotlin
webViewClient = object : WebViewClient() {
    override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
        val host = request.url.host ?: return true
        if (AppConfig.allowedHosts.contains(host)) return false
        // ブロック + Snackbar表示
        return true
    }
}
```

### OAuth（Custom Tabs）

```kotlin
val customTabsIntent = CustomTabsIntent.Builder().build()
customTabsIntent.launchUrl(context, Uri.parse(AppConfig.oauthUrl))

// コールバック受取: AndroidManifest の intent-filter で todoapp://callback を処理
// MainActivity の onNewIntent でトークンを取り出す
```

---

## build.gradle 主要依存

```kotlin
// Room
implementation("androidx.room:room-runtime:2.6.1")
implementation("androidx.room:room-ktx:2.6.1")
ksp("androidx.room:room-compiler:2.6.1")

// Retrofit
implementation("com.squareup.retrofit2:retrofit:2.9.0")
implementation("com.squareup.retrofit2:converter-gson:2.9.0")

// Navigation Compose
implementation("androidx.navigation:navigation-compose:2.7.6")

// Custom Tabs
implementation("androidx.browser:browser:1.8.0")

// EncryptedSharedPreferences
implementation("androidx.security:security-crypto:1.1.0-alpha06")

// Compose BOM
implementation(platform("androidx.compose:compose-bom:2024.02.00"))
```
