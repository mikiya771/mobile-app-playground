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

### 状態の種類と置き場所

| 状態の種類 | 例 | 置き場所 |
|---|---|---|
| UIローカル状態 | ドロップダウン開閉・アニメーション | ウィジェット自身（`StatefulWidget`） |
| データ・ビジネス状態 | Todoリスト・フィルター選択 | ページ層 → 引数で流す |

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

### State Hoisting（状態の引き上げ）とコールバック

データ・ビジネス状態はページ層に置き、引数で下に流す。イベントはコールバックで上に返す。

```
React:                          Flutter:

Page (useState)                 Page (StatefulWidget / setState)
  ├── DisplayA (props)            ├── DisplayA (StatelessWidget / 引数)
  ├── DisplayB (props)            ├── DisplayB (StatelessWidget / 引数)
  └── DisplayC (props)            └── DisplayC (StatelessWidget / 引数)
```

```dart
// ページ層が状態を持つ
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
      onToggle: _toggle,  // コールバックで渡す
    );
  }
}

// ウィジェット層は引数だけ見る
class TodoList extends StatelessWidget {
  const TodoList({required this.todos, required this.onToggle});
  final List<Todo> todos;
  final void Function(String id) onToggle;
  ...
}
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

Dart のオブジェクト生成は軽いため、React のような細かいメモ化は通常不要。

---

## 5. setState の粒度

```dart
// ページ全体が setState すると、ツリー内の全 build() が再実行される
build() {
  return Column(children: [
    HeavyListWidget(),
    CounterDisplay(count: _counter),
  ]);
}
```

`HeavyListWidget` が `const` でない場合、`_counter` に無関係でも `build()` が走る。
対策は `const` をつけること、またはウィジェットを細かく分割して `const` を使いやすくすること。

---

## 6. 非同期データの取得

| React | Flutter |
|---|---|
| `useEffect` + `useState` | `FutureBuilder` |

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
// Flutter: FutureBuilder
FutureBuilder<List<Todo>>(
  future: fetchTodos(),
  builder: (context, snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const CircularProgressIndicator();
    }
    if (snapshot.hasError) return Text('エラー: ${snapshot.error}');
    return TodoList(todos: snapshot.data!);
  },
)
```

---

## 7. ライフサイクル

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

## 8. ナビゲーション

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
5. **状態はページ層に置いて引数で流す**。UIローカル状態だけウィジェット自身が持つ
