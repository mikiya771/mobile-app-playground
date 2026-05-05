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

### Step 3: レイアウトWidget を触る ✅

**現在の main.dart の構成**

```
TodoListPage（Scaffold）
  ├── AppBar
  ├── body: TodoList
  │     ├── FilterTabBar（Row + Expanded × 3）
  │     └── Expanded → ListView
  │           ├── TodoCard × 3（Row: アイコン + Expanded(タイトル) + PriorityBadge）
  └── FloatingActionButton
```

**やること**

1. シミュレーターで TODO リストのダミー画面が表示されることを確認
2. `FilterTabBar` の `Expanded` を外してみる → タブが横幅を取らなくなることを確認
3. `TodoList` の `Expanded` を外してみる → `ListView` がエラーになることを確認（Columnの中でListViewは高さが無限大になるため）
4. `TodoCard` の `mainAxisAlignment` や `crossAxisAlignment` を変えてみる
5. **追加課題**: `TodoCard` に `description` フィールドを追加して、タイトルの下に小さいテキストで表示する（Column を入れ子にする）

---

## Phase 2: TODO一覧画面（UIだけ）

### Step 4: モデルクラス Todo を作る ✅

**作成したファイル**: `lib/models/todo.dart`

**やること**

1. `lib/models/todo.dart` を開いて `Todo` クラスと `TodoPriority` enum を読む
2. `main.dart` の `_dummyTodos` を見て、モデルがどう使われているか確認する
3. `PriorityBadge` の `_labels` / `_colors` マップを見て、色のマッピングがUIレイヤーにあることを確認
4. **追加課題**: `_dummyTodos` に自分でTodoを1件追加してみる
5. **追加課題**: `copyWith()` を使って、既存の Todo の `isCompleted` を反転した新しい Todo を作ってみる（`debugPrint` で確認）

---

### Step 5 & 6: インタラクションを追加する ✅

**やること**

1. チェックアイコンをタップ → 完了/未完了がトグルし取り消し線が出ることを確認
2. フィルタータブをタップ → 「未完了」「完了」で絞り込まれることを確認
3. `pages/todo_list_page.dart` の `_toggle` メソッドを読んで、`copyWith` でイミュータブルに更新していることを確認
4. `_filteredTodos` の `switch` 式を読んで、全ケースを網羅しないとエラーになることを確認
5. **追加課題**: フィルター「未完了」に切り替えた後、チェックをつけるとそのアイテムがリストから消えることを確認（フィルターが即時に反映される）

---

## Phase 3: 永続化（sqflite）

### Step 7: sqflite で CRUD を実装する

**目標**: `sqflite` を使って Todo をローカル DB に保存・読み込みする

---

## Phase 4: ナビゲーション（go_router）

### Step 8: 一覧 → 詳細WebView → 編集フォームを繋ぐ

### Step 9: AuthGuard を追加する

---

## Phase 5: API連携（dio）

### Step 10: JSONPlaceholder から Todo を取得・同期する

---

## Phase 6: WebView

### Step 11: webview_flutter で Todo 詳細ページを表示する

### Step 12: ホワイトリスト制御を実装する

---

## Phase 7: 認証

### Step 13: ログイン画面（WebView + JS Bridge）

### Step 14: SecureStorage でトークン管理・AuthGuard

### Step 15: OAuthフロー（ASWebAuthenticationSession）
