# Flutter 学習ノート（読み物）

外出先でも読める概念まとめ。手を動かす課題は `exercises.md` を参照。

---

## 進捗

- [x] Step 1: main.dart を読んでWidgetツリーを理解する
- [x] Step 2: StatelessWidget / StatefulWidget の違いを体感する
- [x] Step 3: レイアウトWidget（Column / Row / Container）を触る
- [x] Step 4: モデルクラス Todo を作る
- [ ] Step 5: ハードコードのリストを ListView で表示する
- [ ] Step 6: 完了チェック・優先度バッジを作る
- [ ] Step 7: StateProvider でフィルター状態を管理する（Riverpod）
- [ ] Step 8: AsyncNotifier でTodoリストを管理する（Riverpod）
- [ ] Step 9: sqfliteでCRUDを実装する
- [ ] Step 10: 一覧 → 詳細WebView → 編集フォームを繋ぐ（go_router）
- [ ] Step 11: AuthGuardを追加する
- [ ] Step 12: JSONPlaceholderからTodoを取得・同期する（dio）
- [ ] Step 13: webview_flutter でTodo詳細ページを表示する
- [ ] Step 14: ホワイトリスト制御を実装する
- [ ] Step 15: ログイン画面（WebView + JS Bridge）
- [ ] Step 16: SecureStorage でトークン管理・AuthGuard
- [ ] Step 17: OAuthフロー（ASWebAuthenticationSession）

---

## アーキテクチャ方針

### context の使用ルール

| アクセス方法 | ウィジェット層 | ページ層 |
|---|---|---|
| `Theme.of(context)` | ✅ 許容 | ✅ 許容 |
| `MediaQuery.of(context)` | ❌ 引数で渡す | ✅ 許容 |
| `Navigator` / `context.go()` | ❌ コールバックで渡す | ✅ 許容 |
| `ref.watch()` (Riverpod) | ❌ | ✅ 許容 |
| `ScaffoldMessenger.of(context)` | ❌ | ✅ 許容 |

**理由**: ウィジェット層が `context` を通じて上位に依存すると、ウィジェットの置き場所が制約される。`Theme.of(context)` はFlutterのレンダリング基盤と不可分なので例外とする。

### データフローの原則

- **状態はページ層で持つ**（`StatefulWidget` + `setState`）
- **データは引数で下に流す**（prop drilling）
- **イベントはコールバックで上に返す**
- **Riverpod は導入しない**（非同期・横断的な状態が genuinely 必要になった時点で判断する）

```
TodoListPage（StatefulWidget・状態を持つ）
  ├── _todos, _filter など
  └── TodoList(
        todos: todos,                        // データ: 引数で渡す
        onToggle: (id) => setState(...),     // イベント: コールバックで返す
      )
        └── TodoCard(
              todo: todo,
              onToggle: onToggle,
            )
```

---

## Phase 1: Flutterの基礎

### Step 1: Widgetツリーとは何か

Flutter のUIはすべて **Widget の入れ子（ツリー）** で表現される。
HTML の DOM ツリーに近い概念だが、Flutter ではレイアウト・スタイル・インタラクションもすべて Widget として表現する。

```
main()
└── runApp(MyApp)
      └── MaterialApp          ← アプリ全体の設定箱
            └── MyHomePage（StatefulWidget）
                  └── _MyHomePageState
                        └── Scaffold
                              ├── AppBar
                              ├── body: Column
                              │     ├── Text
                              │     └── Text（カウンター）
                              └── FloatingActionButton
```

**MaterialApp が提供するもの**

| 機能 | 詳細 |
|---|---|
| テーマ | `Theme.of(context)` でツリーのどこからでも参照できる |
| Navigator | 画面スタックの管理（push / pop） |
| Localizations | 言語・地域設定 |

MaterialApp を外すと `Theme.of(context)` が null になりエラーになる。

---

**Widget は「設計図」であって「インスタンス」ではない**

Flutter は setState() が呼ばれるたびに `build()` を再実行し、新しい Widget ツリーを生成する。
でも実際のDOMを毎回作り直すのは遅い → Flutter は **Element ツリー（実態）** と差分を比較して必要な部分だけ更新する。
Widget は軽量な設計図なので、毎回作り直してもコストが低い。

---

### Step 2: StatelessWidget と StatefulWidget

**どちらを使うかの判断**

| ウィジェット例 | 状態が必要？ | 選択 |
|---|---|---|
| ラベル・アイコン・静的テキスト | No | StatelessWidget |
| テキスト入力・チェックボックス・カウンター | Yes | StatefulWidget |
| APIデータを取得して表示 | Yes（非同期） | 後でRiverpod |

**StatelessWidget の特徴**

- コンストラクタ引数はすべて `final`（変更不可）
- 自分では setState() を呼べない → 親が setState() すると親の build() が走り、子も再生成される
- `const` コンストラクタが使える → 引数が同じなら Flutter がビルドをスキップして最適化

```dart
class CounterDisplay extends StatelessWidget {
  const CounterDisplay({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Text('$count', style: Theme.of(context).textTheme.displayLarge);
  }
}
```

**StatefulWidget の特徴**

- Widget クラスと State クラスの2つが必ずセットになる
- 状態は State オブジェクトに置く（Widget は毎回作り直されても State は生き続ける）
- `setState(() { ... })` の中で状態を変えると `build()` が再実行される

```dart
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;  // ← ここに状態を置く

  void _increment() => setState(() => _counter++);

  @override
  Widget build(BuildContext context) { ... }
}
```

**なぜ Widget と State を分けるのか**

Flutter は画面更新時に Widget を再生成する。もし状態が Widget に入っていたら、Widget が作り直されるたびに状態もリセットされてしまう。
State は Widget とは別のオブジェクトとして生き続けるので、画面が更新されても状態が保たれる。

---

**Hot Reload / Hot Restart の違い**

| 操作 | 効果 | 使いどころ |
|---|---|---|
| Hot Reload（`r`） | コードを反映、状態は保持 | UIの調整・ロジックの微修正 |
| Hot Restart（`R`） | アプリを再起動、状態リセット | 初期化処理を変えたとき |

IntelliJ では Cmd+S（ファイル保存）で自動 Hot Reload。

---

### Step 3: レイアウトWidget

Flutter のレイアウトは「箱の入れ子」で考える。CSSのFlexboxに近い。

**主要レイアウトウィジェット一覧**

| Widget | 役割 | CSS的なアナロジー |
|---|---|---|
| `Column` | 子を縦に並べる | `flex-direction: column` |
| `Row` | 子を横に並べる | `flex-direction: row` |
| `Expanded` | Column/Row の余ったスペースを占有する | `flex: 1` |
| `Container` | サイズ・色・余白・角丸を一括指定できる箱 | `div` + style |
| `Padding` | 内側に余白を作る | `padding` |
| `SizedBox` | 固定サイズの空白 | `margin` / 固定サイズの `div` |
| `Card` | 影付きの角丸カード | `box-shadow` + `border-radius` |

---

**Column / Row の軸の概念**

```
Column（縦に並ぶ）       Row（横に並ぶ）

  mainAxis = 縦           mainAxis = 横
  crossAxis = 横          crossAxis = 縦

mainAxisAlignment: center → 縦方向に中央寄せ
crossAxisAlignment: center → 横方向に中央寄せ
```

```dart
Column(
  mainAxisAlignment: MainAxisAlignment.center,   // 縦: 中央
  crossAxisAlignment: CrossAxisAlignment.start,  // 横: 左寄せ
  children: [...],
)
```

---

**Expanded の使いどころ**

`Expanded` なしだと、Column の中の ListView がスクロール可能な高さを要求して無限大になりエラーになる。
`Expanded` で包むと「残りスペースを全部使え」という制約が生まれ解決する。

```dart
Column(
  children: [
    FilterTabBar(),       // 固定の高さ
    Expanded(             // ← 残りを全部使う
      child: ListView(...)
    ),
  ],
)
```

React/CSS で言うと「親が `display: flex; flex-direction: column` で子に `flex: 1`」と同じ。

---

**Container vs Padding の使い分け**

```dart
// Padding: 余白だけつけたいとき（意図が明確）
Padding(
  padding: EdgeInsets.all(16),
  child: Text('hello'),
)

// Container: 色・サイズ・角丸なども一緒に指定したいとき
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.blue,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text('hello'),
)
```

---

**Step 3 で作ったウィジェット構成**

```
TodoListPage（Scaffold）
  ├── AppBar
  ├── body: TodoList
  │     ├── FilterTabBar（Row + Expanded × 3 でタブを均等分割）
  │     └── Expanded
  │           └── ListView
  │                 ├── TodoCard（Row: チェックアイコン + Expanded(タイトル) + バッジ）
  │                 ├── TodoCard
  │                 └── TodoCard
  └── FloatingActionButton
```

### Step 4: モデルクラス

**モデルはFlutterに依存しない純粋なDartクラスにする**

`Color` や `Widget` をモデルに持たせると、テストや他プラットフォームへの移植が難しくなる。
表示上の色・ラベルはUIレイヤー（Widget）で変換する。

```
lib/
  models/
    todo.dart    ← 純粋Dartクラス。import は dart:core のみ
  main.dart      ← Flutter依存。モデルの変換（color/label）はここで行う
```

**TodoPriority enum**

```dart
enum TodoPriority { low, medium, high }
```

Dart の enum は Java/Swift と同様に型安全。文字列ではなく enum を使うことで、タイポや未網羅のケースをコンパイル時に検出できる。

**immutable（イミュータブル）な設計**

Flutter では状態をイミュータブルにすることが推奨される。`Todo` を変更するのではなく、`copyWith()` で新しいインスタンスを作る。

```dart
// 完了状態を反転する
final updated = todo.copyWith(isCompleted: !todo.isCompleted);
```

React の「state を直接変更せず新しいオブジェクトを返す」のと同じ考え方。

**`if` を children の中に書ける**

```dart
Column(
  children: [
    Text(todo.title),
    if (todo.description.isNotEmpty)   // ← description があるときだけ表示
      Text(todo.description),
  ],
)
```

Dart のコレクションリテラルには `if` / `for` が書ける。JSXの `{condition && <Element />}` に相当する。

**ListView.separated で区切り線/余白を管理する**

```dart
ListView.separated(
  itemCount: todos.length,
  separatorBuilder: (_, __) => const SizedBox(height: 8),
  itemBuilder: (context, index) => TodoCard(todo: todos[index]),
)
```

`ListView` に直接 `SizedBox` を並べるより、`separated` を使うとアイテムとアイテム間の余白を一か所で管理できる。

---

## セットアップメモ

- プロジェクト: `flutter_app/`（`--platforms ios,android` で作成）
- iOSシミュレーター: iPhone 16（UDID: `1787F496-6762-4418-A152-FFD0073FBD32`）
- Androidエミュレーター: Pixel 9 API 36（`emulator-5554`）
- 起動: IntelliJから（File → Invalidate Caches 後に安定）
- Hot Reload: IntelliJ のファイル保存（Cmd+S）で自動反映
- エラー「Entrypoint isn't within the current project」→ File → Invalidate Caches → Invalidate and Restart で解消
