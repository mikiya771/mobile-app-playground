# TODO App 共通仕様

マルチプラットフォーム学習用TODOアプリの共通仕様。
各プラットフォーム実装はこの仕様に従い、具体的な技術選定は各ディレクトリの `docs/spec.md` に記載する。

---

## 1. データモデル

### Todo

| フィールド | 型 | 説明 |
|---|---|---|
| id | String | 主キー。ローカル生成はUUID、APIインポートは `api_{id}` |
| title | String | タイトル（必須） |
| description | String | 説明（任意、デフォルト空文字） |
| isCompleted | Boolean | 完了フラグ（デフォルト false） |
| priority | Enum | 優先度（low / medium / high） |
| createdAt | DateTime | 作成日時 |

> 詳細ページのURLは `{baseUrl}/todos/{id}` で自動生成する。urlフィールドは持たない。

### TodoPriority

| 値 | 表示ラベル | カラー |
|---|---|---|
| low | 低 | 緑 |
| medium | 中 | オレンジ |
| high | 高 | 赤 |

---

## 2. 画面構成

ハイブリッド構成（パターンC）: 詳細はWebViewが担い、編集だけネイティブフォームに戻す。

```
LoginScreen（ネイティブ）
├── [自社ログイン] → LoginWebViewScreen
│     ↓ JS Bridge でトークン受取 → SecureStorage保存
└── [OAuthログイン] → OSブラウザ（ASWebAuthenticationSession / Custom Tabs）
      ↓ コールバックURLスキームでトークン受取 → SecureStorage保存

TodoListScreen
├── TodoDetailWebViewScreen
│   └── TodoFormScreen（編集）
└── TodoFormScreen（新規）
```

### LoginScreen

- 2つのログインボタン: 「自社アカウントでログイン」「OAuthでログイン」
- ログアウト後や未認証時に表示

### LoginWebViewScreen

- 自社ログインページ（デモ: `assets/login.html`）をWebViewで表示
- ホワイトリスト: `auth.example.com` のみ許可（デモはローカルHTML）
- 認証成功時: JS Bridge経由でネイティブにトークンを渡す
- トークン受取後: SecureStorageに保存 → TodoListScreenへ遷移

### TodoListScreen

- フィルタータブ: すべて / 未完了 / 完了
- Todoをリスト表示
  - タイトル（完了時は取り消し線）
  - 優先度バッジ
  - 完了チェックボックス（タップで即トグル）
- スワイプ削除
- 追加ボタン → TodoFormScreen（新規）
- API同期ボタン → リモートからインポート（ローディング表示あり）
- ログアウトボタン → トークン削除 → LoginScreenへ

### TodoDetailWebViewScreen

- `{baseUrl}/todos/{id}` をWebViewで表示
- ホワイトリスト制御（セクション4参照）
- ナビゲーションバー: タイトル / 編集ボタン / 削除ボタン / リロード
- 編集ボタン → TodoFormScreen（編集）をModal表示
- 削除ボタン → 確認ダイアログ → 削除後一覧に戻る

### TodoFormScreen

| 入力項目 | 種類 | バリデーション |
|---|---|---|
| タイトル | テキスト | 必須 |
| 説明 | テキスト（複数行） | 任意 |
| 優先度 | セグメントコントロール（低/中/高） | デフォルト: 中 |

- 新規作成・編集で同一フォームを使い回す
- 保存 → ローカルDBに保存 → 前の画面に戻る

---

## 3. ナビゲーション

| 遷移 | 方式 |
|---|---|
| 未認証 → LoginScreen | 起動時の認証ガード |
| LoginScreen → LoginWebViewScreen | Push |
| LoginScreen → OAuth | OSブラウザ起動（アプリ離脱） |
| 認証完了 → TodoListScreen | ルート置換（バック不可） |
| TodoListScreen → TodoDetailWebViewScreen | Push |
| TodoDetailWebViewScreen → TodoFormScreen（編集） | Modal |
| TodoListScreen → TodoFormScreen（新規） | Modal |
| TodoFormScreen → 前の画面 | Dismiss |
| TodoDetailWebViewScreen（削除後） → TodoListScreen | Pop |
| ログアウト → LoginScreen | ルート置換（バック不可） |

---

## 4. WebViewホワイトリスト仕様

すべてのWebView画面に共通するナビゲーション制御。

```
AppConfig.allowedHosts:
  - "jsonplaceholder.typicode.com"  （詳細ページ用、デモ）
  - "auth.example.com"              （ログイン用、デモはローカルHTML）
```

| 状況 | 挙動 |
|---|---|
| 許可ドメインへのナビゲーション | 許可 |
| 許可ドメイン外へのリンクタップ | ブロック + アラート表示 |
| 初期URLが許可ドメイン外 | エラー画面を表示 |

---

## 5. 認証フロー

```
アプリ起動
  ↓
SecureStorageに auth_token があるか？
  ├── あり → TodoListScreen
  └── なし → LoginScreen
               ├── 自社ログイン
               │     LoginWebViewScreen（ローカルHTML）
               │       ↓ JS Bridge: postMessage({token: "mock_token"})
               │     トークン保存 → TodoListScreen
               └── OAuthログイン
                     ASWebAuthenticationSession / Custom Tabs
                       ↓ todoapp://callback?token=mock_oauth_token
                     トークン保存 → TodoListScreen
```

- URLスキーム: `todoapp://callback`
- デモトークン: 固定文字列で可（実際の検証なし）
- ログアウト: トークン削除のみ

---

## 6. API仕様

### エンドポイント

```
GET https://jsonplaceholder.typicode.com/todos?_limit=20
```

### レスポンス → Todoへのマッピング

| APIフィールド | Todoフィールド | 備考 |
|---|---|---|
| id | id | `api_{id}` に変換 |
| title | title | そのまま |
| completed | isCompleted | そのまま |
| （なし） | description | 固定値 `"APIから取得"` |
| （なし） | priority | 固定値 `medium` |

### 同期仕様

- ユーザー操作（同期ボタン）でのみ実行
- idが既存と重複する場合はスキップ（上書きしない）

---

## 7. ローカル永続化

- Todoの全フィールドを永続化する
- アプリ再起動後も保持される
- 具体的なストレージ技術は各プラットフォームのspecに委ねる

### 採用技術の対応表

| 実装 | 技術 | 備考 |
|---|---|---|
| Flutter | sqflite | SQLiteの薄いラッパー |
| iOS SwiftUI | SwiftData | CoreData上に構築されたSwift製モダンAPI（iOS 17+） |
| iOS Storyboard | CoreData | NSPersistentContainer + NSFetchedResultsController |
| Android Compose | Room | SQLiteのKotlin製ORM |
| Android XML | Room | 同上 |

### SQLiteを使う実装向け共通スキーマ

```sql
CREATE TABLE todos (
  id          TEXT PRIMARY KEY,
  title       TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  isCompleted INTEGER NOT NULL DEFAULT 0,
  priority    TEXT NOT NULL DEFAULT 'medium',
  createdAt   INTEGER NOT NULL
);
```

---

## 8. エラーハンドリング

- API通信失敗 → 画面上部 or ダイアログでエラーメッセージ表示
- フォームバリデーション失敗 → フィールド近傍にエラーメッセージ表示
- WebViewホワイトリスト違反 → アラートでブロック理由を表示
- SecureStorage読み書き失敗 → ログアウト扱いとしてLoginScreenへ

---

## 9. 実装一覧

各ディレクトリに `docs/spec.md` として個別仕様を配置する。

```
zed/flutter/
├── docs/spec.md                 ← このファイル（共通仕様）
├── flutter_app/                 ← Flutter スタンドアロン（先に実装・動作確認用）
├── flutter_module/              ← Flutter Add to App module（flutter_appから移植）
├── ios_swiftui/                 ← iOS SwiftUI + SwiftData
├── ios_storyboard/              ← iOS UIKit + CoreData
├── android_compose/             ← Android Jetpack Compose + Room
└── android_xml/                 ← Android XML + Fragment + Room
```

**実装順序の推奨:** `flutter_app` → `flutter_module` → `ios_swiftui` → `ios_storyboard` → `android_compose` → `android_xml`
