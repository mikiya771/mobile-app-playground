# Flutter 実装仕様

共通仕様: `docs/spec.md` を参照。
本ファイルはFlutter（Add to App module）固有の技術選定・構成を記載する。

---

## 技術スタック

| レイヤー | 技術 |
|---|---|
| 状態管理 | flutter_riverpod |
| ナビゲーション | go_router（AuthGuard付き） |
| ローカルDB | sqflite |
| API通信 | dio |
| WebView（詳細・ログイン） | webview_flutter |
| OAuth | flutter_web_auth_2 |
| セキュアストレージ | flutter_secure_storage |
| ID生成 | uuid |

---

## ディレクトリ構成

```
lib/
├── main.dart
├── app.dart
├── config/
│   └── app_config.dart          # ホワイトリスト・URLスキーム・baseUrl定義
├── models/
│   └── todo.dart
├── db/
│   └── todo_database.dart       # sqflite操作
├── api/
│   └── todo_api.dart            # dio クライアント
├── repositories/
│   ├── todo_repository.dart
│   └── auth_repository.dart     # flutter_secure_storage操作
├── providers/
│   ├── todo_providers.dart      # AsyncNotifierProvider
│   └── auth_providers.dart      # 認証状態・AuthGuard
├── router/
│   └── app_router.dart          # go_router + redirect によるAuthGuard
├── screens/
│   ├── login_screen.dart
│   ├── login_webview_screen.dart  # JS Bridge受信
│   ├── todo_list_screen.dart
│   ├── todo_detail_webview_screen.dart  # ホワイトリスト制御
│   └── todo_form_screen.dart
└── widgets/
    ├── todo_list_item.dart
    └── priority_badge.dart

assets/
└── login.html                   # モックログインページ
```

---

## 主要実装ポイント

### AuthGuard（go_router redirect）

```dart
redirect: (context, state) {
  final isLoggedIn = ref.read(authProvider).isLoggedIn;
  final isLoginRoute = state.matchedLocation.startsWith('/login');
  if (!isLoggedIn && !isLoginRoute) return '/login';
  if (isLoggedIn && isLoginRoute) return '/';
  return null;
}
```

### JS Bridge受信（LoginWebViewScreen）

```dart
controller.addJavaScriptChannel(
  'authBridge',
  onMessageReceived: (msg) {
    final token = jsonDecode(msg.message)['token'];
    ref.read(authProvider.notifier).login(token);
  },
);
```

### WebViewホワイトリスト制御

```dart
NavigationDelegate(
  onNavigationRequest: (req) {
    final host = Uri.parse(req.url).host;
    if (AppConfig.allowedHosts.contains(host)) {
      return NavigationDecision.navigate;
    }
    // ブロック + アラート表示
    return NavigationDecision.prevent;
  },
)
```

### OAuth（flutter_web_auth_2）

```dart
final result = await FlutterWebAuth2.authenticate(
  url: AppConfig.oauthUrl,
  callbackUrlScheme: 'todoapp',
);
final token = Uri.parse(result).queryParameters['token']!;
```

---

## pubspec.yaml 依存パッケージ

```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  go_router: ^14.0.0
  dio: ^5.7.0
  sqflite: ^2.3.3
  path: ^1.9.0
  uuid: ^4.5.1
  webview_flutter: ^4.10.0
  flutter_web_auth_2: ^4.0.0
  flutter_secure_storage: ^9.2.2
```
