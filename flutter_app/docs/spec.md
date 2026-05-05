# Flutter App（スタンドアロン）実装仕様

共通仕様: `docs/spec.md` を参照。
本ファイルはフルFlutterアプリ固有の技術選定・構成を記載する。

## flutter_module との違い

| 観点 | flutter_app（本ファイル） | flutter_module |
|---|---|---|
| 用途 | スタンドアロンアプリ | ネイティブアプリへの組み込み |
| プロジェクト種別 | `flutter create --template app` | `flutter create --template module` |
| エントリーポイント | `main()` のみ | 複数エントリーポイント可 |
| ios/ android/ | あり（Flutter管理） | なし（ホストアプリが管理） |
| Platform Channel | 不要 | ネイティブ連携に使用 |
| WebView | webview_flutter で完結 | ネイティブWebViewに委譲も可 |

---

## 技術スタック

flutter_module と同一。

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

flutter_module と同一構成。`module:` セクションが `pubspec.yaml` にない点のみ異なる。

```
lib/
├── main.dart
├── app.dart
├── config/app_config.dart
├── models/todo.dart
├── db/todo_database.dart
├── api/todo_api.dart
├── repositories/
│   ├── todo_repository.dart
│   └── auth_repository.dart
├── providers/
│   ├── todo_providers.dart
│   └── auth_providers.dart
├── router/app_router.dart
├── screens/
│   ├── login_screen.dart
│   ├── login_webview_screen.dart
│   ├── todo_list_screen.dart
│   ├── todo_detail_webview_screen.dart
│   └── todo_form_screen.dart
└── widgets/
    ├── todo_list_item.dart
    └── priority_badge.dart

assets/
└── login.html

ios/      ← Flutter管理（flutter_moduleにはない）
android/  ← Flutter管理（flutter_moduleにはない）
```

---

## 実装の進め方

flutter_app を先に実装し、動作確認が取れたコードを flutter_module に移植する。
両者は `lib/` 以下のコードをほぼ共有できる。
