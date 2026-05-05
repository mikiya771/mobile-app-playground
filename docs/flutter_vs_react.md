# Flutter と React の比較ノート

React の知識を起点に Flutter の概念を理解するための対応表。

---

## 1. コンポーネント / ウィジェット

React と Flutter はどちらも「UIを木構造で表現する」という設計思想が共通している。

| React | Flutter |
|---|---|
| コンポーネント（関数 or クラス） | Widget（StatelessWidget or StatefulWidget） |
| JSX で入れ子を表現 | `build()` メソッドでウィジェットを入れ子にする |
| props | コンストラクタ引数（`final` フィールド） |
| children prop | `child:` / `children:` 引数 |

```jsx
// React
function CounterDisplay({ count }) {
  return <Text>{count}</Text>;
}
```

```dart
// Flutter
class CounterDisplay extends StatelessWidget {
  const CounterDisplay({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Text('$count');
  }
}
```

---

## 2. 状態管理の基本

### ローカル状態

| React | Flutter |
|---|---|
| `useState` | `StatefulWidget` + `setState()` |
| Hook は関数コンポーネントの中に書く | State クラスのフィールドに書く |

```jsx
// React
function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(c => c + 1)}>{count}</button>;
}
```

```dart
// Flutter
class _CounterState extends State<Counter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => setState(() => _count++),
      child: Text('$_count'),
    );
  }
}
```

### State Hoisting（状態の引き上げ）

React でよく使う「ページで state を持って、下は stateless に」というパターンは Flutter でも有効で推奨される。

```
React:                          Flutter:

Page (useState)                 Page (StatefulWidget / setState)
  ├── DisplayA (props)            ├── DisplayA (StatelessWidget / 引数)
  ├── DisplayB (props)            ├── DisplayB (StatelessWidget / 引数)
  └── DisplayC (props)            └── DisplayC (StatelessWidget / 引数)
```

---

## 3. 再描画の仕組み

ここが React と Flutter で**最も重要な違い**。

### React の再描画

```
state 変更
  → 仮想DOM を再生成（コンポーネント関数を再実行）
  → 前回の仮想DOM と差分比較（Reconciliation）
  → 差分がある部分だけ実 DOM に反映
```

### Flutter の再描画

Flutter は 3層構造になっている。

```
state 変更（setState）
  → Widget ツリーを再生成（build() を再実行）← 軽量な Dart オブジェクトを作るだけ
      ↓ 差分比較
  → Element ツリーを更新（差分がない部分は使い回す）← React の仮想DOM に相当
      ↓ 差分のある部分だけ
  → RenderObject を更新（実際に描画する重い処理）
```

**Widget の再生成は軽い。** Widget は画面の「設計図」であって、実際のピクセルを持たない。Dart オブジェクトを作り直すだけなのでコストが低い。実際の描画（RenderObject）は差分がある部分しか走らない。

---

## 4. 再描画の最適化

### React.memo → Flutter の `const`

```jsx
// React: メモ化して不要な再レンダリングを防ぐ
const CounterLabel = React.memo(({ text }) => <Text>{text}</Text>);
```

```dart
// Flutter: const をつけるとビルドが完全にスキップされる
const CounterLabel(text: '操作してみよう'),
```

`const` ウィジェットは**コンパイル時に同一オブジェクトと確定**し、親が `setState()` しても再実行されない。React.memo より強力で、実行時のコストがゼロ。

ただし `const` が使えるのは「引数が定数（実行時に変化しない）」場合のみ。

```dart
// これは const にできない（_counter は実行時に変わる）
CounterDisplay(count: _counter),

// これは const にできる（テキストが変わらない）
const CounterLabel(text: '固定テキスト'),
```

### useMemo / useCallback → Flutter では基本不要

Dart のオブジェクト生成は軽いため、React のような細かいメモ化は通常不要。重い計算が必要な場合は後述の Riverpod で対処する。

---

## 5. setState の粒度問題

```dart
// ページ全体が setState すると、関係ないウィジェットも build() が走る
build() {
  return Column(children: [
    HeavyListWidget(),      // ← counter と無関係なのに再実行される
    CounterDisplay(count: _counter),
  ]);
}
```

React なら `React.memo` や `useMemo` で対処するところ。Flutter の答えは **Riverpod の `Consumer`**（Step 7 で学ぶ）。

```dart
// Consumer で囲んだ部分だけ再描画される
Column(children: [
  HeavyListWidget(),       // ← counter が変わっても再実行されない
  Consumer(
    builder: (context, ref, child) {
      final count = ref.watch(counterProvider);
      return CounterDisplay(count: count);
    },
  ),
])
```

---

## 6. グローバル状態管理

| React | Flutter |
|---|---|
| Context + useReducer | Riverpod（`Notifier` / `AsyncNotifier`） |
| Redux / Zustand | Riverpod |
| React Query（サーバー状態） | Riverpod の `AsyncNotifier` + dio |

### Context vs Riverpod

```jsx
// React Context
const CounterContext = createContext(0);

function App() {
  const [count, setCount] = useState(0);
  return (
    <CounterContext.Provider value={{ count, setCount }}>
      <DeepChild />
    </CounterContext.Provider>
  );
}

function DeepChild() {
  const { count } = useContext(CounterContext);
  return <Text>{count}</Text>;
}
```

```dart
// Riverpod
final counterProvider = StateProvider<int>((ref) => 0);

class DeepChild extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider); // プロバイダーを直接参照
    return Text('$count');
  }
}
```

Riverpod の利点：
- Provider の定義がグローバルスコープにあり、どこからでも `ref.watch()` で参照できる
- Context を props drilling する必要がない
- 依存関係（どの Provider が何を参照しているか）が静的に解析できる

### このプロジェクトでの方針：prop drilling を基本とする

Riverpod は導入せず、ページ層の `StatefulWidget` + `setState` で状態を管理する。
データは引数で下に流し、イベントはコールバックで上に返す。

```dart
// ✅ ページ層が状態を持つ
class _TodoListPageState extends State<TodoListPage> {
  List<Todo> _todos = _dummyTodos;

  void _toggle(String id) => setState(() {
    _todos = _todos.map((t) =>
      t.id == id ? t.copyWith(isCompleted: !t.isCompleted) : t
    ).toList();
  });

  @override
  Widget build(BuildContext context) {
    return TodoList(
      todos: _todos,
      onToggle: _toggle,   // コールバックで渡す
    );
  }
}

// ✅ ウィジェット層は引数だけ見る
class TodoList extends StatelessWidget {
  const TodoList({required this.todos, required this.onToggle});
  final List<Todo> todos;
  final void Function(String id) onToggle;
  ...
}
```

React の「ページで useState して、子は props だけ」と同じ発想。

---

## 7. 非同期データの取得

| React | Flutter |
|---|---|
| `useEffect` + `useState` | `FutureBuilder` or Riverpod の `AsyncNotifier` |
| React Query の `useQuery` | Riverpod の `AsyncNotifier` |

```jsx
// React
function TodoList() {
  const [todos, setTodos] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('/todos').then(r => r.json()).then(data => {
      setTodos(data);
      setLoading(false);
    });
  }, []);

  if (loading) return <Spinner />;
  return todos.map(t => <TodoItem key={t.id} todo={t} />);
}
```

```dart
// Flutter + Riverpod（Step 8 で実装）
class TodoListNotifier extends AsyncNotifier<List<Todo>> {
  @override
  Future<List<Todo>> build() async {
    return await _repository.fetchAll(); // loading/data/error を自動管理
  }
}

class TodoList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoListProvider);
    return todos.when(
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('エラー: $e'),
      data: (list) => ListView(children: list.map((t) => TodoItem(todo: t)).toList()),
    );
  }
}
```

`AsyncNotifier` は React Query の `useQuery` に近い。loading / error / data の3状態を `AsyncValue` として自動管理する。

---

## 8. ライフサイクル

| React | Flutter（State クラス） |
|---|---|
| `useEffect(() => {}, [])` | `initState()` |
| `useEffect(() => () => cleanup(), [])` | `dispose()` |
| `useEffect(() => {}, [dep])` | `didUpdateWidget()` |
| コンポーネントのアンマウント | ウィジェットがツリーから外れる |

```dart
class _MyState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();
    // useEffect(() => {}, []) に相当
  }

  @override
  void dispose() {
    // クリーンアップ（タイマー停止・コントローラー解放など）
    super.dispose();
  }
}
```

---

## 9. ナビゲーション

| React（React Router） | Flutter（go_router） |
|---|---|
| `<Route path="/todos" element={<TodoList />} />` | `GoRoute(path: '/todos', builder: ...)` |
| `useNavigate()` → `navigate('/todos')` | `context.go('/todos')` |
| `useParams()` | `GoRouterState.pathParameters` |
| ガード（PrivateRoute） | `redirect` コールバック |

---

## まとめ：Reactエンジニアが Flutter を学ぶときのポイント

1. **Widget = コンポーネント**。入れ子で UI を作る発想は同じ
2. **StatelessWidget = props だけ受け取る純粋コンポーネント**。React.memo より強い `const` で最適化
3. **StatefulWidget = useState を持つコンポーネント**。ただし Widget と State の2クラスに分かれる
4. **Widget の再生成は軽い**。React の仮想DOM と同様、実際の描画は差分だけ
5. **Riverpod = Context + React Query の代替**。Step 7–8 で導入する
6. **re-render の粒度は Riverpod の Consumer で制御**。React.memo の代わり
