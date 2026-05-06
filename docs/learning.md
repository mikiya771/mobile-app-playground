# Flutter 学習ノート（読み物）

外出先でも読める概念まとめ。手を動かす課題は `exercises.md` を参照。

---

## 進捗

- [x] Step 1: main.dart を読んでWidgetツリーを理解する
- [x] Step 2: StatelessWidget / StatefulWidget の違いを体感する
- [x] Step 3: レイアウトWidget（Column / Row / Container）を触る
- [x] Step 4: モデルクラス Todo を作る
- [x] Step 5: インタラクションを追加する（トグル・フィルター）
- [x] Step 6: タップ操作と状態フローを整理する
- [x] Step 7: sqflite で CRUD を実装する / Riverpod + MVVM + Clean Architecture 導入
- [x] Step 8: 一覧 → 詳細WebView → 編集フォームを繋ぐ（go_router）
- [x] Step 9: AuthGuard を追加する
- [x] Step 10: JSONPlaceholder から Todo を取得・同期する（dio）
- [x] Step 11: webview_flutter で Todo 詳細ページを表示する
- [x] Step 12: ホワイトリスト制御を実装する
- [x] Step 13: ログイン画面（WebView + JS Bridge）
- [x] Step 14: SecureStorage でトークン管理・AuthGuard
- [x] Step 15: OAuthフロー（ASWebAuthenticationSession）

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

状態を2種類に分けて管理する。

| 状態の種類 | 例 | 置き場所 |
|---|---|---|
| UIローカル状態 | ドロップダウンの開閉・アコーディオン・アニメーション | ウィジェット自身（`StatefulWidget`） |
| ビジネス状態 | Todoリスト・フィルター選択・認証 | `Notifier`（ViewModel）|

- **データは引数で下に流す**（prop drilling）
- **イベントはコールバックで上に返す**
- **`ref.watch()` はページ層にのみ書く**。ウィジェット層は引数だけを見る

```
TodoListPage（ConsumerWidget）
  ├── ref.watch(todoListProvider) → state
  └── TodoList(
        todos: state.filteredTodos,   ← 引数で下に流す
        onToggle: notifier.toggle,    ← コールバックで上に返す
      )
        └── TodoCard(
              todo: todo,
              onToggle: onToggle,
            )
```

### Notifier と ViewModel の関係

Notifier は MVVM の ViewModel に対応する。

**基本形: 1 Page : 1 Notifier**
```
TodoListPage  ←→  TodoListNotifier
LoginPage     ←→  LoginNotifier
```

**例外: アプリ横断の共有状態は 1 Notifier : N Pages**
```
AuthNotifier
  ├── LoginPage（ログイン操作）
  ├── ProfilePage（ユーザー情報表示）
  └── AppBar（アバター表示）
```

ページをまたいで同期が必要な状態（認証・カート・通知数など）だけが例外になる。

### React との対応関係

| React | Flutter/Riverpod |
|---|---|
| `useState` | `StatefulWidget` の `setState` |
| `useContext` + Context API | `ref.watch(provider)` |
| Context.Provider | `ProviderScope` + `Provider` |

Riverpod の `Provider` は React の Context に相当する。ウィジェットツリーの外に存在するため、画面回転・バックグラウンド復帰でも状態が保持される。

### 状態の永続化

| 状況 | 状態 |
|---|---|
| 画面回転 | Riverpod Provider に保持される（ProviderScope が生きているため） |
| バックグラウンド → 復帰 | 同上 |
| アプリ完全終了 → 再起動 | **消える**（メモリ解放） |

再起動後も復元するには sqflite などで永続化し、`build()` 内の `_load()` で読み直す（現在の実装はこの方式）。

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
  features/
    todo/
      todo.dart    ← 純粋Dartクラス。import は dart:core のみ
  main.dart        ← Flutter依存。モデルの変換（color/label）はここで行う
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

### Step 5 & 6: インタラクションと状態フロー

**StatefulWidget でページ状態を管理する**

`TodoListPage` を `StatefulWidget` に変えて、`_todos` と `_filter` を State に持つ。

```dart
class _TodoListPageState extends State<TodoListPage> {
  List<Todo> _todos = _dummyTodos;
  TodoFilter _filter = TodoFilter.all;
  ...
}
```

`StatefulWidget` の `build()` は `State` クラスの中に書く。`StatefulWidget` クラス自体には `createState()` だけ置く。

**Dart 3 の `switch` 式**

```dart
List<Todo> get _filteredTodos => switch (_filter) {
  TodoFilter.all       => _todos,
  TodoFilter.active    => _todos.where((t) => !t.isCompleted).toList(),
  TodoFilter.completed => _todos.where((t) => t.isCompleted).toList(),
};
```

`switch` が「式」として値を返せる（Dart 3 以降）。enum の全ケースを網羅しないとコンパイルエラーになるため、分岐漏れをコンパイル時に検出できる。

**コールバックで状態変更を上に伝える**

ウィジェット層は状態を持たず、タップされたら「誰かに伝える」だけ。

```
GestureDetector.onTap
  → () => onToggle(todo.id)   // コールバックを呼ぶ
    → _TodoListPageState._toggle(id)  // ここで setState
      → _todos = _todos.map(...copyWith...).toList()
```

**`GestureDetector` でタップを検知する**

```dart
GestureDetector(
  onTap: () => onToggle(todo.id),
  child: Icon(...),
)
```

`GestureDetector` は任意のウィジェットにタップ・スワイプ・ドラッグなどのジェスチャーを付与できる。`InkWell`（タップ時に波紋エフェクト付き）という代替もある。

---

## Phase 2: アーキテクチャと状態管理

### Step 7: sqflite + Riverpod + MVVM + Clean Architecture

#### sqflite による永続化

`sqflite` は Flutter の SQLite ラッパー。iOS/Android どちらでも動作する。

```dart
// DB を開く（なければ onCreate で作成）
final db = await openDatabase(
  join(await getDatabasesPath(), 'todo.db'),
  version: 1,
  onCreate: (db, _) => db.execute('CREATE TABLE todos (...)'),
);

// CRUD
await db.query('todos');                          // SELECT
await db.insert('todos', row);                   // INSERT
await db.update('todos', row, where: 'id = ?'); // UPDATE
await db.delete('todos', where: 'id = ?');      // DELETE
```

Flutter のモデルクラスは Map に変換して渡す必要がある（`_toRow` / `_fromRow`）。

#### Clean Architecture の3層

```
Presentation Layer  Widget（View）/ Notifier（ViewModel）
Domain Layer        Entity（Todo）/ Repository Interface
Data Layer          Repository 実装（sqflite）
```

依存の向きは **外 → 内**。Presentation は Domain を知っているが Domain は Presentation を知らない。

```dart
// Domain Layer: 抽象だけを定義（sqflite を知らない）
abstract class TodoRepositoryInterface {
  Future<List<Todo>> findAll();
  Future<void> insert(Todo todo);
  Future<void> update(Todo todo);
  Future<void> delete(String id);
}

// Data Layer: 実装を提供（sqflite に依存してよい）
class TodoRepository implements TodoRepositoryInterface { ... }
```

#### Riverpod を DI コンテナとして使う

```dart
// Singleton の代わりに Provider で管理
final todoRepositoryProvider = Provider<TodoRepositoryInterface>((ref) {
  return TodoRepository();
});
```

Singleton は「隠れた依存」でテスト時に差し替えられない。Provider 経由にすることでテスト時に `MockRepository` を注入できる。

```dart
// テストでの差し替え
ProviderContainer(overrides: [
  todoRepositoryProvider.overrideWithValue(InMemoryTodoRepository()),
])
```

#### MVVM: Notifier が ViewModel

```
View（Widget）   ← state を受け取って描画
ViewModel        ← Notifier。ビジネスロジックを持つ
Model            ← Entity + Repository
```

```dart
class TodoListNotifier extends Notifier<TodoListState> {
  @override
  TodoListState build() {
    _repo = ref.read(todoRepositoryProvider);  // DI
    _load();                                   // 初期データ取得
    return const TodoListState();
  }

  Future<void> toggle(String id) async {
    // 1. リポジトリを更新
    await _repo.update(updated);
    // 2. state を更新（UI が再描画される）
    state = state.copyWith(todos: ...);
  }
}
```

`build()` は同期で初期 state を返し、非同期処理（`_load()`）はファイアアンドフォーゲットで開始する。

#### State は immutable

```dart
class TodoListState {
  const TodoListState({
    this.todos = const [],
    this.filter = TodoFilter.all,
    this.loading = true,
  });

  // 一部だけ変えた新しいインスタンスを返す
  TodoListState copyWith({...}) => TodoListState(...);
}
```

`state = state.copyWith(...)` で新しいインスタンスを代入することで Riverpod が変化を検知して UI を再描画する。state を直接ミュートすると検知されない。

#### `Dismissible` でスワイプ削除

```dart
Dismissible(
  key: ValueKey(todo.id),
  direction: DismissDirection.endToStart,   // 右 → 左スワイプ
  background: Container(/* 赤い背景 */),
  onDismissed: (_) => onDelete(todo.id),
  child: TodoCard(...),
)
```

リストアイテムを左スワイプで削除する UI パターン。`key` には一意な値が必要（id を使う）。

---

### Step 8: go_router で画面遷移を実装する

#### なぜ go_router か

Flutter には画面遷移の仕組みが2世代ある。

| | Navigator 1.0 | Navigator 2.0 / go_router |
|---|---|---|
| 遷移方法 | `Navigator.push(context, ...)` | `context.go('/todos/123')` |
| URL | なし（モバイルでは不要だが Web で困る） | パスベース URL |
| ディープリンク | 手動実装が必要 | 標準サポート |
| 戻るボタン制御 | 複雑 | 宣言的に定義できる |

go_router は Navigator 2.0 を使いやすくラップした公式推奨パッケージ。

#### Route 定義

```dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const TodoListPage(),
    ),
    GoRoute(
      path: '/todos/:id',               // :id がパスパラメータ
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return TodoDetailPage(todoId: id);
      },
    ),
  ],
);
```

React Router の `<Route path="/todos/:id">` と同じ発想。

#### `context.go()` vs `context.push()`

| メソッド | 動作 | 使いどころ |
|---|---|---|
| `context.go('/path')` | スタックを置き換える | タブ切り替え・ルートへの移動 |
| `context.push('/path')` | スタックに積む（戻れる） | 詳細ページへの遷移 |
| `context.pop()` | 1つ戻る | 詳細から一覧へ戻る |

一覧 → 詳細は `push`（戻るボタンで一覧に戻れる）。

#### `MaterialApp.router` への切り替え

go_router を使うには `MaterialApp` の代わりに `MaterialApp.router` を使う。

```dart
// Before
MaterialApp(home: const TodoListPage())

// After
MaterialApp.router(routerConfig: router)
```

`home` の代わりに `routerConfig` で GoRouter インスタンスを渡す。

#### アーキテクチャとの関係

ナビゲーション（`context.go()` / `context.push()`）はページ層でのみ行う。

```dart
// ✅ ページ層でナビゲーション
// TodoListPage の中
onTap: (id) => context.push('/todos/$id'),

// ✅ ウィジェット層はコールバックを呼ぶだけ
// TodoCard の中
onTap: () => onTap(todo.id),   // context.push は知らない
```

ウィジェット層が `context.go()` を直接呼ぶと、そのウィジェットが特定のルート構造に依存してしまい再利用できなくなる。

#### パスパラメータで id を渡す設計

```
/todos/abc-123
         ↑
         todo.id（UUID）を URL に埋め込む
```

`TodoDetailPage` は id だけ受け取り、`ref.watch(todoListProvider)` から該当 Todo を探す。

```dart
class TodoDetailPage extends ConsumerWidget {
  const TodoDetailPage({super.key, required this.todoId});
  final String todoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todo = ref.watch(todoListProvider)
        .todos
        .firstWhere((t) => t.id == todoId);
    ...
  }
}
```

State を引数として渡さず、id だけを渡して Provider から引く設計。こうすることで詳細ページが一覧の状態変更を自動的に反映できる。

#### 今回の実装スコープ

```
TodoListPage（一覧）
  ├── Todo カードをタップ → context.push('/todos/:id')
  └── TodoDetailPage（詳細）
        ├── タイトル・説明・優先度を表示
        ├── 編集ボタン → ダイアログで title / description / priority を編集
        └── 戻るボタン → context.pop()
```

---

### Step 9: AuthGuard（ルートガード）

#### AuthGuard とは

認証されていないユーザーが保護されたルートにアクセスしようとしたとき、ログイン画面にリダイレクトする仕組み。

```
未ログイン状態で /todos にアクセス
  → router の redirect で検知
    → /login にリダイレクト
      → ログイン成功
        → /todos に戻る
```

React Router の `<PrivateRoute>` / Next.js の `middleware` に相当する概念。

#### go_router の `redirect`

`GoRouter` に `redirect` コールバックを渡すことでルートガードを宣言的に実装できる。

```dart
final router = GoRouter(
  redirect: (context, state) {
    final isLoggedIn = /* 認証状態を確認 */;
    final isOnLogin = state.matchedLocation == '/login';

    if (!isLoggedIn && !isOnLogin) return '/login';  // 未ログイン → /login へ
    if (isLoggedIn && isOnLogin) return '/';          // ログイン済みで /login → / へ
    return null;                                       // null = リダイレクトしない
  },
  routes: [...],
);
```

`redirect` は全ルート遷移の前に呼ばれる。`null` を返すと通常のナビゲーションが続行される。

#### `refreshListenable` で認証状態の変化を Router に伝える

`redirect` はデフォルトでは画面遷移時にしか呼ばれない。ログイン成功など「状態が変わったタイミング」でも再評価させるには `refreshListenable` を使う。

```dart
final router = GoRouter(
  refreshListenable: authNotifierListenable,  // ← 変化を監視
  redirect: (context, state) { ... },
  routes: [...],
);
```

`refreshListenable` は `Listenable`（`ChangeNotifier` など）を受け取る。Riverpod の Provider は `Listenable` ではないため、`ProviderListenable` をブリッジする小さなアダプターが必要になる。

```dart
// Riverpod の Provider → Listenable に変換するアダプター
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}
```

`authProvider` が変化するたびに `notifyListeners()` が呼ばれ、Router が `redirect` を再評価する。

#### 認証状態の設計

認証状態は「アプリ横断の共有状態」なので `AsyncNotifier` で管理する。

```dart
class AuthState {
  const AuthState({this.isLoggedIn = false});
  final bool isLoggedIn;
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    // 起動時: 保存済みトークンを確認（Step 14 で SecureStorage に変更）
    return const AuthState(isLoggedIn: false);
  }

  Future<void> login() async { ... }
  Future<void> logout() async { ... }
}
```

#### ログイン後のリダイレクト先（deep link 対応）

ユーザーが `/todos/abc` を開こうとしてログイン画面に飛ばされた場合、ログイン後は `/todos/abc` に戻るべき。

```dart
redirect: (context, state) {
  if (!isLoggedIn && !isOnLogin) {
    // 元の遷移先を from パラメータで保持
    final from = state.matchedLocation;
    return '/login?from=${Uri.encodeComponent(from)}';
  }
  ...
}

// ログイン成功後
final from = state.uri.queryParameters['from'] ?? '/';
context.go(from);
```

#### ベストプラクティス

| 項目 | 推奨 | 理由 |
|---|---|---|
| 認証状態の管理 | `AsyncNotifier` + Provider | Singleton 禁止。テスト時に差し替え可能 |
| トークン保存 | `flutter_secure_storage` | Keychain（iOS）/ Keystore（Android）に暗号化保存 |
| router との連携 | `refreshListenable` | ログイン/ログアウト後に即リダイレクト |
| `redirect` の条件 | ログイン済み + `/login` → `/` | ログイン済みでログイン画面を表示しない |
| deep link 保持 | `?from=` クエリパラメータ | ログイン後に元のページに戻れる |
| ログアウト処理 | `ref.invalidate(authProvider)` | Provider をリセットして初期状態に戻す |
| API エラー 401 | Repository からエラーを throw | ViewModel/Page で catch して logout() を呼ぶ |

#### 今回の実装スコープ（Step 9）

本物の OAuth は Step 15 で実装するため、ここでは**仮ログイン**（ボタンを押したらログイン状態になる）でガードの仕組みだけを作る。

```
未ログイン
  → アプリ起動 → /login にリダイレクト
      → 「ログイン」ボタンタップ → authNotifier.login()
          → authProvider が更新 → refreshListenable が発火
              → redirect が再評価 → / にリダイレクト
                  → TodoListPage が表示される

ログイン済み
  → / にアクセス → リダイレクトなし → TodoListPage
  → /login にアクセス → / にリダイレクト（二重ログイン防止）
```

---

### Step 10: dio で API 通信 + DataSource 分離

#### なぜ dio か

Flutter の HTTP 通信には `http`（標準）と `dio` がある。

| | `http` | `dio` |
|---|---|---|
| インターセプター | なし | あり（認証ヘッダー自動付与、エラー共通処理） |
| リトライ | 手動 | プラグインで対応可 |
| キャンセル | 難しい | `CancelToken` で対応 |
| 採用場面 | 簡単な1〜2本 | 認証・エラーハンドリングが必要な本番アプリ |

インターセプターが使える `dio` が本番アプリでは事実上の標準。

#### DataSource 分離（Step 7 で先送りにした内容）

Step 7 では Repository が直接 sqflite を叩いていた。API が加わったタイミングで **DataSource** を切り出す。

```
Repository（調停役）
  ├── LocalDataSource  ← sqflite
  └── RemoteDataSource ← dio / API
```

Repository はどちらのデータソースを使うか判断するだけ。ビジネスロジック（Notifier）はデータの出所を知らない。

```dart
// Repository の責務
Future<List<Todo>> findAll() async {
  // ローカルを正とし、リモートで差分同期
  final local = await _local.findAll();
  if (local.isNotEmpty) return local;         // キャッシュがあればそれを返す
  final remote = await _remote.fetchAll();    // なければ API から取得
  await _local.insertAll(remote);             // ローカルに保存
  return remote;
}
```

#### DataMapper パターン

API レスポンス（JSON）と Domain Entity（`Todo`）は別物として扱う。

```
JSON レスポンス
  ↓ DataMapper（変換）
Todo（Domain Entity）
```

```dart
// API レスポンスの形（JSONPlaceholder の場合）
{
  "id": 1,
  "title": "delectus aut autem",
  "completed": false,
  "userId": 1
}

// Domain Entity の形（アプリ内）
Todo(id: "uuid", title: "...", isCompleted: false, priority: medium, ...)
```

変換を Repository や DataSource に混ぜると責務が増えすぎる。DataMapper（または `fromJson` ファクトリ）として分離する。

```dart
// RemoteDataSource で API の形を表す DTO
class TodoDto {
  const TodoDto({required this.id, required this.title, required this.completed});
  final int id;
  final String title;
  final bool completed;

  factory TodoDto.fromJson(Map<String, dynamic> json) => TodoDto(
    id: json['id'] as int,
    title: json['title'] as String,
    completed: json['completed'] as bool,
  );

  // DTO → Domain Entity
  Todo toEntity() => Todo(
    id: id.toString(),
    title: title,
    isCompleted: completed,
    createdAt: DateTime.now(),
  );
}
```

#### dio の基本

```dart
final dio = Dio(BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'));

// GET /todos
final response = await dio.get('/todos');
final list = (response.data as List)
    .map((e) => TodoDto.fromJson(e as Map<String, dynamic>))
    .toList();

// インターセプター（認証ヘッダーの自動付与）
dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) {
    options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  },
  onError: (error, handler) {
    if (error.response?.statusCode == 401) {
      // 認証切れ → ログアウト処理
    }
    handler.next(error);
  },
));
```

#### エラーハンドリングの方針

API エラーは Repository 層で `AppException` に変換して上位に伝える。Notifier では `AsyncError` になり、Page の `asyncState.when(error: ...)` で表示する。

```
DioException（ネットワークエラー・4xx・5xx）
  ↓ Repository で catch → AppException に変換
AsyncError（Riverpod）
  ↓ asyncState.when(error: (e, _) => ...)
エラー UI 表示
```

#### ベストプラクティス

| 項目 | 推奨 | 理由 |
|---|---|---|
| HTTP クライアント | `dio` | インターセプター・エラー処理が充実 |
| DTO と Entity の分離 | `TodoDto` → `Todo.fromDto()` | API 仕様変更の影響を DataSource 層に閉じ込める |
| Repository の役割 | キャッシュ戦略の判断のみ | DataSource の組み合わせを調停する |
| エラー型 | 独自 `AppException` | `DioException` を Domain 層に漏らさない |
| `dio` インスタンス | `Provider` で管理 | インターセプターを一か所で設定 |
| オフライン対応 | Local 優先・Remote で同期 | sqflite をキャッシュとして使う |

#### 今回の実装スコープ

```
RemoteDataSource（dio）
  → JSONPlaceholder GET /todos → TodoDto リスト
    → TodoDto.toEntity() で Todo に変換
      → LocalDataSource（sqflite）にキャッシュ保存
        → UI に表示

同期ボタン（AppBar）
  → API から最新を取得 → ローカルを上書き → UI 更新
```

ディレクトリ構成の変化:
```
features/todo/
  todo.dart
  todo_repository_interface.dart
  todo_repository.dart          ← Repository（調停役）に変更
  todo_repository_provider.dart
  data/
    local/
      todo_local_data_source.dart   ← 旧 todo_repository.dart の sqflite ロジック
    remote/
      todo_remote_data_source.dart  ← 新規: dio で API 通信
      todo_dto.dart                 ← 新規: API レスポンスの DTO + DataMapper
  ...
```

---

### Step 11: webview_flutter で WebView を表示する

#### webview_flutter とは

Flutter 公式の WebView パッケージ。iOS は `WKWebView`、Android は `WebView` をそれぞれネイティブで使い、Flutter Widget として扱える。

```dart
WebViewWidget(controller: controller)
```

`WebViewController` でナビゲーション・JS 実行・ページ読み込みを制御する。

#### 基本的な使い方

```dart
final controller = WebViewController()
  ..setJavaScriptMode(JavaScriptMode.unrestricted)
  ..loadRequest(Uri.parse('https://example.com'));

// Widget として埋め込む
WebViewWidget(controller: controller)
```

`WebViewController` はウィジェットのライフサイクルと独立して生存できる。`StatefulWidget` の `State` で初期化するか、Riverpod の `Provider` で管理する。

#### ナビゲーションの制御（`NavigationDelegate`）

ページ遷移の前後に処理を挟める。ホワイトリスト制御（Step 12）はここで実装する。

```dart
controller.setNavigationDelegate(NavigationDelegate(
  onPageStarted: (url) { /* ローディング開始 */ },
  onPageFinished: (url) { /* ローディング完了 */ },
  onNavigationRequest: (request) {
    // true を返すと遷移許可、false で遷移キャンセル
    if (request.url.startsWith('https://myapp.com')) {
      return NavigationDecision.navigate;
    }
    return NavigationDecision.prevent;  // ← ホワイトリスト外はブロック
  },
));
```

#### JS Bridge（Flutter ↔ WebView 通信）

WebView 内の JavaScript と Flutter が双方向に通信できる。Step 13 のログイン実装で使う。

```dart
// Flutter → JS
controller.runJavaScript('window.postMessage("hello", "*")');

// JS → Flutter（JavaScriptChannel）
controller.addJavaScriptChannel(
  'FlutterBridge',
  onMessageReceived: (message) {
    // WebView 内の JS から FlutterBridge.postMessage("data") で受信
    print(message.message);
  },
);
```

#### `WebViewController` の置き場所

`WebViewController` は非同期で初期化されるため、`StatefulWidget` の `initState()` で作成するか、Riverpod の `Provider` で管理する。

```dart
// StatefulWidget パターン（シンプルなケース）
class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }
}
```

`WebViewController` はページ固有の状態なので `StatefulWidget` で持つのが自然。ビジネスロジックを含まないため Notifier に上げる必要はない。

#### ローディング表示パターン

WebView のロードが完了するまでインジケーターを表示する。`StatefulWidget` でローカル状態として管理する典型例。

```dart
class _WebViewPageState extends State<WebViewPage> {
  bool _isLoading = true;  // UIローカル状態 → StatefulWidget が持つ

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
```

`_isLoading` は WebView のロード状態という UI ローカル状態。Notifier に上げる必要はない（アーキテクチャ方針通り）。

#### iOS の設定（Info.plist）

HTTP（非 HTTPS）の URL を許可する場合は `Info.plist` に設定が必要。今回は HTTPS のみ使うので不要。

```xml
<!-- HTTP を許可する場合のみ（今回は不要） -->
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```

#### ベストプラクティス

| 項目 | 推奨 | 理由 |
|---|---|---|
| `WebViewController` の置き場所 | `StatefulWidget.initState()` | ページ固有の UI 状態。Notifier に上げる必要なし |
| ローディング状態 | Widget ローカル状態（`_isLoading`） | UIローカル状態の典型例 |
| JS 有効化 | 必要な場合のみ `unrestricted` | セキュリティリスクを最小化 |
| 外部リンク | `NavigationDelegate` でブロック | ホワイトリスト外への遷移を防ぐ |
| バック操作 | `controller.canGoBack()` で確認 | WebView 内の戻るとアプリの戻るを区別 |
| URL のバリデーション | `Uri.tryParse()` で null チェック | 不正 URL でのクラッシュを防ぐ |

#### 今回の実装スコープ

既存の `TodoDetailPage`（Flutter ネイティブ UI）に加えて、WebView を使ったページを新設する。

```
routes:
  /todos/:id          → TodoDetailPage（Flutter UI・既存）
  /webview?url=...    → WebViewPage（新規）

TodoDetailPage の AppBar に「Web で開く」ボタン
  → context.push('/webview?url=https://jsonplaceholder.typicode.com/todos/:id')
    → WebViewPage で表示
```

`WebViewPage` は URL をクエリパラメータで受け取る汎用ページとして実装。Step 12 以降のホワイトリスト・ログインでも再利用する。

---

### Step 12: ホワイトリスト制御

#### ホワイトリストとは

WebView 内でユーザーがリンクをタップして外部サイトに飛んでしまうのを防ぐ仕組み。許可ドメインのリストを持ち、それ以外への遷移はブロックする。

```
ユーザーがリンクをタップ
  → NavigationDelegate.onNavigationRequest が呼ばれる
    → URL がホワイトリストに含まれる？
        Yes → NavigationDecision.navigate（許可）
        No  → NavigationDecision.prevent（ブロック）
              + 外部ブラウザで開く / スナックバーで通知
```

#### 設計の選択肢

| 方法 | 特徴 |
|---|---|
| `WebViewPage` にハードコード | 最もシンプル。ページ固有のルールに向く |
| 設定ファイル（`whitelist.dart`）に定数として定義 | アプリ全体で共通ルールを持てる |
| サーバーから取得 | 動的に変更できるが複雑になる |

今回は**設定ファイルに定数**として定義する。将来サーバー取得に変える場合も Repository 層で差し替えるだけでよい。

#### `NavigationDelegate` でホワイトリストを実装する

```dart
NavigationDelegate(
  onNavigationRequest: (request) {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;

    final isAllowed = WebViewConfig.allowedHosts.any(
      (host) => uri.host == host || uri.host.endsWith('.$host'),
    );

    if (isAllowed) return NavigationDecision.navigate;

    // ブロックされたリンクを外部ブラウザで開く（url_launcher）
    launchUrl(uri, mode: LaunchMode.externalApplication);
    return NavigationDecision.prevent;
  },
)
```

サブドメインも許可する場合は `uri.host.endsWith('.$host')` で判定する。

#### `url_launcher` で外部ブラウザを開く

ホワイトリスト外の URL はアプリ内で開かず、Safari / Chrome などの外部ブラウザに渡す。

```dart
import 'package:url_launcher/url_launcher.dart';

await launchUrl(
  Uri.parse('https://external.com'),
  mode: LaunchMode.externalApplication,  // 外部ブラウザで開く
);
```

`LaunchMode` の種類：

| モード | 動作 |
|---|---|
| `externalApplication` | Safari / Chrome などのデフォルトブラウザ |
| `inAppBrowserView` | アプリ内ブラウザ（Safari View Controller） |
| `platformDefault` | OS のデフォルト動作 |

#### ホワイトリストの設計

```dart
// lib/config/web_view_config.dart
abstract final class WebViewConfig {
  static const List<String> allowedHosts = ['localhost', '127.0.0.1'];
}
```

`abstract final class` はインスタンス化・継承を禁止する定数クラスの書き方。コンストラクタを隠す `_()` より明示的。

今回はローカルの nginx サーバー（`localhost:8080`）のみをホワイトリストに入れる。外部サイト（`flutter.dev` 等）へのリンクはブロックして外部ブラウザで開く。

#### ベストプラクティス

| 項目 | 推奨 | 理由 |
|---|---|---|
| ホワイトリストの定義場所 | 設定ファイル（`config/`）| 変更箇所を一か所に集中 |
| ブロック時の動作 | 外部ブラウザで開く | ユーザーがリンクを開けない状況を防ぐ |
| サブドメイン | `endsWith` で許可 | `api.example.com` なども通す |
| `file://` や `about:` | 明示的に許可 or ブロック | 意図しない挙動を防ぐ |
| エラーハンドリング | `Uri.tryParse()` で null チェック | 不正 URL でのクラッシュを防ぐ |
| 初期 URL のバリデーション | `WebViewPage` 表示前にチェック | 空文字や不正 URL を弾く |

#### ローカル Web サーバー（nginx + docker-compose）

WebView のホワイトリスト動作を確認するために、ローカルで nginx を起動する。

```yaml
# docker-compose.yml
services:
  nginx:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html:ro
      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
```

```nginx
# nginx/nginx.conf
server {
    listen 80;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

起動: `docker-compose up -d`（`zed/flutter/` ディレクトリで実行）

#### iOS ATS (App Transport Security)

iOS はデフォルトで `http://` の通信をブロックする。開発中に `localhost` へ HTTP でアクセスするには `Info.plist` に例外を追加する。

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>localhost</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

**本番環境では `localhost` 以外の HTTP 例外を追加しないこと**。App Store レビューでリジェクト対象になる場合がある。

#### 今回の実装スコープ

```
zed/flutter/
  html/index.html              ← ローカル HTML（ホワイトリスト内/外のリンクを含む）
  nginx/nginx.conf             ← nginx 設定
  docker-compose.yml           ← nginx 起動定義

flutter_app/lib/config/
  web_view_config.dart         ← ホワイトリスト定数（allowedHosts = ['localhost', '127.0.0.1']）

WebViewPage
  → NavigationDelegate に allowedHosts チェックを追加
  → ブロック時は url_launcher で外部ブラウザに渡す
  → ブロックされた旨を SnackBar で通知

TodoDetailPage
  → "Web で開く" の URL を http://localhost:8080/todos/{id} に変更

ios/Runner/Info.plist
  → NSAppTransportSecurity に localhost の HTTP 例外を追加
```

### Step 13: ログイン画面（WebView + JS Bridge）

#### JS Bridge とは

WebView 内の JavaScript と Flutter が双方向に通信する仕組み。

```
JS → Flutter : JavaScriptChannel.postMessage()
Flutter → JS : WebViewController.runJavaScript()
```

通常の WebView はサンドボックスなので Flutter のコードを直接呼べない。JS Bridge はその壁に「窓口」を開ける。

#### JavaScriptChannel（JS → Flutter）

`addJavaScriptChannel` で登録したチャンネル名がグローバル JS オブジェクトになる。

```dart
// Flutter 側
_controller.addJavaScriptChannel(
  'FlutterAuth',
  onMessageReceived: (JavaScriptMessage msg) {
    final data = jsonDecode(msg.message);  // {"token": "..."}
    ref.read(authProvider.notifier).loginWithToken(data['token']);
  },
);
```

```javascript
// HTML 側
FlutterAuth.postMessage(JSON.stringify({ token: 'dummy-token' }));
```

`addJavaScriptChannel` は `WebViewController` の初期化時（`initState`）に呼ぶ。ページ遷移後も有効。

#### runJavaScript（Flutter → JS）

Flutter から JS 関数を呼び出す場合。主にページ読み込み後の初期化や状態注入に使う。

```dart
await _controller.runJavaScript('showError("ログインに失敗しました")');
```

戻り値が必要な場合は `runJavaScriptReturningResult()` を使う（String を返す）。

#### セキュリティ上の注意点

| 項目 | 問題 | 対策 |
|---|---|---|
| チャンネルの露出 | 外部ページから `FlutterAuth.postMessage()` を呼ばれる | ホワイトリストで外部ページへの遷移をブロック（Step 12） |
| メッセージの検証 | 不正なトークン形式を受け入れる | `try/catch` + 型チェック |
| `file://` アクセス | ローカルファイルが Bridge を使う | `JavaScriptMode` を `unrestricted` にしない（今回は localhost のみなので許容） |

Bridge のセキュリティは「どのページが Bridge を持つか」が核心。`LoginWebViewPage` のような用途固有のページにだけ Bridge を追加し、汎用 `WebViewPage` には付けない。

#### ConsumerStatefulWidget

WebView ページは：
- `StatefulWidget` が必要（`WebViewController` はローカル状態）
- `ConsumerWidget` が必要（`authProvider` を呼ぶ）

この両方が必要なときは `ConsumerStatefulWidget` を使う。

```dart
class LoginWebViewPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<LoginWebViewPage> createState() => _LoginWebViewPageState();
}

class _LoginWebViewPageState extends ConsumerState<LoginWebViewPage> {
  // ref が使える + StatefulWidget のライフサイクルも持つ
}
```

#### 今回の実装スコープ

```
html/login.html                      ← ログインフォーム（JS Bridge 呼び出しあり）

features/auth/pages/
  login_web_view_page.dart           ← ConsumerStatefulWidget
    → JavaScriptChannel 'FlutterAuth' を登録
    → メッセージ受信で authProvider.notifier.login() を呼ぶ
    → router redirect が / にリダイレクト（既存の仕組みを再利用）

router.dart
  → /login を LoginWebViewPage に差し替え

auth_provider.dart
  → login() はそのまま使用（トークン管理は Step 14 で追加）
```

---

## セットアップメモ

- プロジェクト: `flutter_app/`（`--platforms ios,android` で作成）
- iOSシミュレーター: iPhone 16（UDID: `1787F496-6762-4418-A152-FFD0073FBD32`）
- Androidエミュレーター: Pixel 9 API 36（`emulator-5554`）
- 起動: IntelliJから（File → Invalidate Caches 後に安定）
- Hot Reload: IntelliJ のファイル保存（Cmd+S）で自動反映
- エラー「Entrypoint isn't within the current project」→ File → Invalidate Caches → Invalidate and Restart で解消

### Step 14: SecureStorage でトークン管理

#### SharedPreferences と SecureStorage の違い

| | SharedPreferences | flutter_secure_storage |
|---|---|---|
| 保存場所 | UserDefaults (iOS) / SharedPreferences (Android) | Keychain (iOS) / Keystore (Android) |
| 暗号化 | なし | OS レベルで暗号化 |
| 用途 | テーマ・言語設定など | 認証トークン・パスワード |

セキュリティが必要な値は必ず `flutter_secure_storage` に保存する。

#### FlutterSecureStorage の API

```dart
const storage = FlutterSecureStorage();

await storage.write(key: 'token', value: 'abc123');
final token = await storage.read(key: 'token');   // String?
await storage.delete(key: 'token');
```

全て `async`。key は任意の文字列。

#### build() でトークンを読み込んで自動ログイン

`AsyncNotifier.build()` はアプリ起動時に一度だけ呼ばれる。ここでトークンを読めばアプリ再起動後の自動ログインが実現できる。

```dart
@override
Future<AuthState> build() async {
  final token = await ref.read(tokenStorageProvider).read();
  return AuthState(isLoggedIn: token != null, token: token);
}
```

`token != null` がそのままログイン判定になる。

#### TokenStorage を Provider で DI する

```dart
// lib/features/auth/token_storage.dart
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(const FlutterSecureStorage());
});

class TokenStorage {
  const TokenStorage(this._storage);
  final FlutterSecureStorage _storage;
  static const _key = 'auth_token';

  Future<String?> read() => _storage.read(key: _key);
  Future<void> write(String token) => _storage.write(key: _key, value: token);
  Future<void> delete() => _storage.delete(key: _key);
}
```

`FlutterSecureStorage` を直接 `AuthNotifier` に持たせず、`TokenStorage` 経由にすることで差し替えやテストがしやすくなる。

#### 今回の実装スコープ

```
lib/features/auth/
  token_storage.dart        ← TokenStorage クラス + Provider
  auth_provider.dart        ← build() でトークン読み込み、login/logout で書き込み/削除
```

---

### Step 15: OAuth フロー（ASWebAuthenticationSession）

#### なぜ WebView で OAuth をやってはいけないか

| 方式 | 問題点 |
|---|---|
| アプリ内 WebView | アプリがパスワードを盗み見できる。ブラウザのセッション（Cookie）が使えない |
| `ASWebAuthenticationSession` | OS が仲介。アプリからは認可コードしか見えない。Safari の SSO セッションを使える |

OAuth 2.0 のベストプラクティス（RFC 8252）では、外部ブラウザ or `ASWebAuthenticationSession` を使うことが要求される。

#### Authorization Code Flow（簡略版）

```
App → ブラウザ起動（認可 URL）
      ユーザーがログイン・承認
      ブラウザ → flutterapp://callback?code=xxx にリダイレクト
flutter_web_auth_2 がコールバックを捕捉 → App に戻す
App → code をトークンと交換（今回はモック）
App → トークンを SecureStorage に保存
```

#### flutter_web_auth_2 の使い方

```dart
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

final result = await FlutterWebAuth2.authenticate(
  url: 'http://localhost:8080/oauth/authorize',
  callbackUrlScheme: 'flutterapp',  // Info.plist に登録したスキーム
);

final code = Uri.parse(result).queryParameters['code'];
```

iOS では `ASWebAuthenticationSession` が使われ、システムダイアログが表示される。

#### URL スキームの登録（Info.plist）

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>flutterapp</string>
    </array>
  </dict>
</array>
```

`flutterapp://callback` というコールバック URL をシステムが認識してアプリに渡すために必要。

#### JS Bridge との連携

OAuth ボタンは `login.html` に置く。タップ時は JS Bridge で Flutter に「OAuth を開始して」と伝え、Flutter 側で `FlutterWebAuth2.authenticate()` を呼ぶ。

```javascript
// login.html
function handleOAuth() {
  FlutterAuth.postMessage(JSON.stringify({ type: 'oauth' }));
}
```

```dart
// login_web_view_page.dart
void _onAuthMessage(JavaScriptMessage message) {
  final data = jsonDecode(message.message);
  if (data['type'] == 'oauth') {
    _startOAuthFlow();     // ← Flutter ネイティブ処理へ移譲
  } else {
    // 通常ログイン
  }
}
```

WebView 内の JS から直接 `ASWebAuthenticationSession` を呼ぶ手段はない。Bridge 経由でネイティブに移譲するのが正しいパターン。

#### 今回の実装スコープ

```
html/login.html                        ← 「OAuth でログイン」ボタンを追加
html/oauth/authorize.html              ← モック認可画面

flutter_app/ios/Runner/Info.plist      ← CFBundleURLTypes に flutterapp を登録

lib/features/auth/
  pages/login_web_view_page.dart       ← type:'oauth' メッセージで _startOAuthFlow()
  auth_provider.dart                   ← login(token:) で任意のトークンを受け取り保存
```
