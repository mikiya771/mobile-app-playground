# Flutter 演習シート（手を動かす）

PC前でコードを書くときに開く実践シート。
概念の説明は `learning.md` を参照。

---

## Phase 1: Flutterの基礎

### Step 1: Widgetツリーを読む ✅

**やること**

1. `flutter_app/lib/main.dart` を開いて Widget ツリーを上から追う
2. `MaterialApp` → `MyHomePage` → `Scaffold` → `Column` の入れ子を確認
3. `colorScheme` の `seedColor` を `Colors.green` に変えて Cmd+S → Hot Reload で色が変わるか確認
4. `_counter++` を `_counter += 2` に変えて Hot Reload → カウントが2ずつ増えるか確認
5. `R`（Hot Restart）して状態（カウント）がリセットされることを確認

**確認ポイント**
- Hot Reload は状態を保持するが、Hot Restart はリセットする
- `Theme.of(context).colorScheme.inversePrimary` が `seedColor` から自動生成された色であることを確認

---

### Step 2: StatelessWidget を自作する ✅

**現在の main.dart の構造**（Step 2 完了時点）

```
MyHomePage（StatefulWidget）
  └── _MyHomePageState      ← _counter を保持
        ├── CounterDisplay  ← StatelessWidget（count を受け取って表示）
        └── CounterLabel    ← StatelessWidget（text を受け取って表示）
```

**やること**

1. `lib/main.dart` を開いて `CounterDisplay` と `CounterLabel` のコードを読む
2. ▲ボタンを押して数字が増えることを確認
3. ▼ボタンを押して数字が減ることを確認
4. `CounterDisplay` の `Text` スタイルを `displayLarge` → `displayMedium` に変えてHot Reload → サイズが変わることを確認
5. **追加課題**: `CounterLabel` にカウントの正負を表示する（`count > 0 ? 'プラス' : count < 0 ? 'マイナス' : 'ゼロ'`）

**実験してみよう**
- `CounterDisplay` を `const CounterDisplay(count: 0)` のように定数に変えたらどうなるか？
  → コンパイルエラー: StatefulWidget の State 内で定数を渡すと「const は実行時値を受け取れない」と言われる

---

### Step 3: レイアウトWidget を触る（次のStep）

**目標**: Column / Row / Container / Padding / Expanded を使って TODO一覧の「骨格」を作る

**やること（予定）**

1. `Scaffold` の `body` を Column → Row → Container に変えて違いを確認
2. `mainAxisAlignment` / `crossAxisAlignment` の効果を確認
3. `Expanded` で残りスペースを埋める
4. `Padding` / `SizedBox` でスペースを作る
5. TODO一覧のダミーカード1枚を作る（Card + ListTile）

---

## Phase 2: TODO一覧画面（UIだけ）

### Step 4: モデルクラス Todo を作る

**目標**: `lib/models/todo.dart` を作成

```dart
enum TodoPriority { low, medium, high }

class Todo {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final TodoPriority priority;
  final DateTime createdAt;
}
```

---

### Step 5: ハードコードのリストを ListView で表示する

**目標**: ダミーデータのリストを `ListView.builder` で表示

---

### Step 6: 完了チェック・優先度バッジを作る

**目標**: 各 Todo アイテムに Checkbox と優先度バッジ（色付きチップ）を追加

---

## Phase 3: 状態管理（Riverpod）

### Step 7: StateProvider でフィルター状態を管理する

### Step 8: AsyncNotifier でTodoリストを管理する

---

## Phase 4: 永続化（sqflite）

### Step 9: sqfliteでCRUDを実装する

---

## Phase 5: ナビゲーション（go_router）

### Step 10: 一覧 → 詳細WebView → 編集フォームを繋ぐ

### Step 11: AuthGuardを追加する

---

## Phase 6: API連携（dio）

### Step 12: JSONPlaceholderからTodoを取得・同期する

---

## Phase 7: WebView

### Step 13: webview_flutter でTodo詳細ページを表示する

### Step 14: ホワイトリスト制御を実装する

---

## Phase 8: 認証

### Step 15: ログイン画面（WebView + JS Bridge）

### Step 16: SecureStorage でトークン管理・AuthGuard

### Step 17: OAuthフロー（ASWebAuthenticationSession）
