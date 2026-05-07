# Android XML 版 TODO アプリ 仕様書

## 概要

Android 伝統的 View システム（XML レイアウト + ViewBinding）を使った TODO 管理アプリ。
`android_compose/` と同じ機能を XML ベースで実装し、両アーキテクチャの対比を学ぶ。

## 技術スタック

| 層 | 技術 |
|---|---|
| UI | XML レイアウト + ViewBinding |
| コンポーネント | Activity / Fragment |
| ナビゲーション | Navigation Component (NavGraph XML) |
| 状態管理 | ViewModel + LiveData |
| 永続化 | Room (SQLite ORM) |
| API 通信 | Retrofit + OkHttp + Gson |
| 認証トークン | EncryptedSharedPreferences |
| OAuth | Chrome Custom Tabs |

## 画面一覧

| 画面 | Fragment / Activity | 説明 |
|---|---|---|
| ログイン | `LoginFragment` | WebView + JS Bridge |
| TODO 一覧 | `TodoListFragment` | RecyclerView + フィルタータブ |
| TODO 詳細 | `TodoDetailFragment` | 読み取り専用 |
| WebView | `WebViewFragment` | ホワイトリスト制御付き |

## ディレクトリ構成

```
app/src/main/java/com/example/androidxml/
├── MainActivity.kt
├── AppNavGraph（nav_graph.xml）
├── features/
│   └── todo/
│       ├── Todo.kt
│       ├── TodoListFragment.kt
│       ├── TodoDetailFragment.kt
│       ├── TodoAdapter.kt
│       ├── TodoListViewModel.kt
│       ├── TodoRepositoryInterface.kt
│       ├── TodoRepository.kt
│       └── data/
│           ├── local/
│           │   ├── TodoEntity.kt
│           │   ├── TodoDao.kt
│           │   ├── AppDatabase.kt
│           │   └── TodoLocalDataSource.kt
│           └── remote/
│               ├── TodoDto.kt
│               └── TodoRemoteDataSource.kt
├── auth/
│   ├── AuthViewModel.kt
│   ├── LoginFragment.kt
│   └── TokenStorage.kt
└── webview/
    ├── WebViewFragment.kt
    └── WebViewConfig.kt
```

## Compose 版との対応

| Compose | XML |
|---|---|
| `@Composable fun` | XML layout + ViewHolder |
| `setContent { }` | `setContentView(binding.root)` |
| `remember { mutableStateOf() }` | `LiveData` / `MutableStateFlow` |
| `collectAsState()` | `observe {}` |
| `LazyColumn` | `RecyclerView` + `ListAdapter` |
| `NavHost` | `NavHostFragment` (nav_graph.xml) |
| `Scaffold` | `CoordinatorLayout` + `AppBarLayout` |
| `MaterialTheme.colorScheme.primary` | `@color/...` in XML |
