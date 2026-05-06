# アーキテクチャ設計書

## 概要

本ドキュメントは Flutter アプリケーションのアーキテクチャ方針を定める。
設計の軸は以下の3つである。

1. **層の分離**（Clean Architecture）: 変更の影響範囲を限定する
2. **React 哲学の取り込み**（単方向データフロー・宣言的UI）: UI の予測可能性を高める
3. **テスタビリティ**（DI + インターフェース分離）: ビジネスロジックを独立してテストできる

---

## 1. 全体構造：層の分離

アプリケーションを3層に分離する。依存の方向は常に外側から内側へ向かう（内側の層は外側を知らない）。

```
┌──────────────────────────────────────────┐
│           Presentation Layer             │
│   Widget（View）/ Notifier（ViewModel）   │
├──────────────────────────────────────────┤
│              Domain Layer                │
│       Entity / Repository Interface      │
├──────────────────────────────────────────┤
│               Data Layer                 │
│    Repository 実装 / sqflite / API       │
└──────────────────────────────────────────┘

依存の方向:  Presentation → Domain ← Data
```

### 各層の責務

**Presentation Layer**
- UI の描画（Widget）
- ユーザー操作の受け取りとビジネスロジックへの委譲（ViewModel / Notifier）
- Flutter / Riverpod に依存してよい唯一の層

**Domain Layer**
- アプリのコアとなるデータモデル（Entity）
- リポジトリの抽象（Interface）
- Flutter にも Data Layer にも依存しない純粋 Dart

**Data Layer**
- Repository Interface の具体実装
- sqflite・HTTP クライアントなど外部依存を閉じ込める
- Domain Layer の Interface に依存する（逆は不可）

---

## 2. UI パターン：MVVM × MVI × React 哲学

### 2-1. MVVM の採用

UI パターンとして MVVM を採用する。

```
View（Widget）  ←── State を受け取る ───  ViewModel（Notifier）
     └────────── Event / Callback ────→         └── Repository を呼ぶ
```

| 役割 | 実装 |
|---|---|
| View | `StatelessWidget` / `ConsumerWidget` |
| ViewModel | `Notifier` / `AsyncNotifier`（Riverpod） |
| Model | `Entity`（データクラス）+ `Repository` |

### 2-2. MVI の考え方を取り込む（BLoC 的哲学）

ViewModel への「意図（Intent）」は型で明示する。Riverpod Notifier を使う場合はメソッドが Intent に相当する。BLoC を使う場合は `sealed class Event` で明示する。

```dart
// Riverpod Notifier: メソッドが Intent
notifier.toggle(id);
notifier.add(title);

// BLoC: Event が型として記録される
bloc.add(ToggleTodo(id: id));
bloc.add(AddTodo(title: title));
```

複雑な状態遷移・監査ログが必要な場合は BLoC、そうでなければ Notifier で十分。

### 2-3. React 哲学の取り込み

**UI = f(state)**

`build()` は state の純粋関数である。同じ state を渡せば常に同じ UI が得られる。副作用は ViewModel に閉じ込める。

```dart
// ✅ build() は state だけを見て描画する
@override
Widget build(BuildContext context, WidgetRef ref) {
  final todos = ref.watch(todoListProvider);
  return TodoList(todos: todos);
}
```

**単方向データフロー**

```
State（ViewModel）
    ↓ データを引数で渡す
Widget（View）
    ↓ コールバックでイベントを返す
ViewModel のメソッドを呼ぶ
    ↓
State が更新される
    ↓（最初に戻る）
```

React の「props は上から下、イベントは下から上」と同じ発想。

---

## 3. データフローの原則

### 3-1. 状態の種類と置き場所

状態を2種類に分けて管理する。

| 種類 | 例 | 置き場所 |
|---|---|---|
| **ビジネス状態** | Todo リスト・フィルター・認証 | ViewModel（Notifier）|
| **UI ローカル状態** | ドロップダウン開閉・アニメーション | Widget 自身（`StatefulWidget`）|

UI ローカル状態を ViewModel に上げる必要はない。アコーディオンの開閉が Repository のテストに影響することはないからである。

### 3-2. Presentation Layer のデータフロー

```
Page（ConsumerWidget）
  ├── ref.watch(todoListProvider) → todos
  └── TodoList(
        todos: todos,                          // データ: 引数で渡す
        onToggle: (id) => ref.read(...).toggle(id),  // イベント: コールバック
      )
          └── TodoCard(
                todo: todo,
                onToggle: onToggle,            // そのまま下に流す
              )
```

**Page 層が ViewModel の唯一の接触点**。`ref.watch()` / `ref.read()` は Page 層にのみ書く。それ以下の Widget は引数だけを見る。

### 3-3. prop drilling の許容範囲

2〜3層の prop drilling は許容する。それ以上深くなる場合は、中間に別の Page / ConsumerWidget を置くことを検討する。Widget ツリーの奥深くで `ref.watch()` を呼ぶことは避ける。

---

## 4. 依存注入（DI）

### 4-1. Riverpod を DI コンテナとして使う

Riverpod の `Provider` が DI コンテナの役割を担う。Singleton やグローバル変数による依存は使わない。

```dart
// ✅ Riverpod が依存を管理する
final todoRepositoryProvider = Provider<TodoRepositoryInterface>((ref) {
  return TodoRepository();
});

// ❌ Singleton は隠れた依存・差し替え不可
final repo = TodoRepository.instance;
```

### 4-2. Repository は Interface 経由で参照する

```dart
// Domain Layer: 抽象だけを定義
abstract class TodoRepositoryInterface {
  Future<List<Todo>> findAll();
  Future<void> insert(Todo todo);
  Future<void> update(Todo todo);
  Future<void> delete(String id);
}

// Data Layer: 実装を提供
class TodoRepository implements TodoRepositoryInterface { ... }

// テスト: 差し替える
final mockProvider = todoRepositoryProvider.overrideWithValue(
  MockTodoRepository(),
);
```

### 4-3. ProviderScope でアプリを包む

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(child: MyApp()),
  );
}
```

テスト時は `ProviderScope(overrides: [...])` で任意の実装を注入する。

---

## 5. context の使用ルール

`BuildContext` を通じた上位ウィジェットへのアクセスは、以下のルールに従う。

| アクセス方法 | Widget 層 | Page 層 |
|---|---|---|
| `Theme.of(context)` | ✅ 許容 | ✅ 許容 |
| `MediaQuery.of(context)` | ❌ 引数で渡す | ✅ 許容 |
| `Navigator` / `context.go()` | ❌ コールバックで渡す | ✅ 許容 |
| `ref.watch()` / `ref.read()` | ❌ | ✅ 許容 |
| `ScaffoldMessenger.of(context)` | ❌ | ✅ 許容 |

`Theme.of(context)` のみ Widget 層で許容する理由: Flutter のレンダリング基盤と不可分であり、代替手段がないため。

---

## 6. Riverpod と BLoC の使い分け

Riverpod と BLoC は競合ではなく、役割が異なる。

| | Riverpod | BLoC |
|---|---|---|
| 主な役割 | DI コンテナ + ViewModel 実装 | ViewModel の通信パターン |
| Intent の表現 | メソッド呼び出し（暗黙的）| `sealed class Event`（明示的・型安全）|
| 状態の表現 | 任意の型 | `sealed class State` |
| 監査ログ | 別途実装が必要 | イベントストリームで自然に取れる |
| ボイラープレート | 少ない | 多い |

### 使い分けの判断基準

**Riverpod Notifier を選ぶ場合**
- 状態遷移がシンプル
- イベント履歴の追跡が不要
- 開発速度を優先する

**BLoC を選ぶ場合**
- 状態遷移が複雑（ローディング・エラー・リトライなど）
- イベントの監査・再現が必要
- チームが BLoC に習熟している

**両方を使う場合**
Riverpod を DI コンテナとして使い、BLoC インスタンスを Provider で管理する。

```dart
final todoBloCProvider = Provider<TodoBloc>((ref) {
  return TodoBloc(ref.read(todoRepositoryProvider));
});
```

---

## 7. ディレクトリ構成

```
lib/
  main.dart                          # ProviderScope + MaterialApp のみ
  features/
    todo/                            # Todo フィーチャー全体
      todo.dart                      # Domain Layer: Entity（TodoPriority / TodoFilter / Todo）
      todo_repository_interface.dart # Domain Layer: Repository 抽象
      todo_repository.dart           # Data Layer: sqflite 実装
      todo_repository_provider.dart  # DI 定義
      todo_list_provider.dart        # State + Notifier（ViewModel）+ Provider を一本化
      pages/
        todo_list_page.dart          # Presentation Layer: Page（ConsumerWidget）
      widgets/                       # Presentation Layer: 純粋 Widget
        todo_list.dart
        todo_card.dart
        filter_tab_bar.dart
        priority_badge.dart
  # 今後追加予定
  # features/auth/                   # 認証フィーチャー
  # router/                          # go_router 定義
```

**feature-first を採用する理由**

layer-first（`models/`, `repositories/`, `providers/` …）は層ごとにフォルダを切るが、機能追加時に複数フォルダをまたいで変更が発生する。
feature-first は「一つの機能に関係するファイルを一か所に集める」ため、変更の局所性が高い。

**`todo_list_provider.dart` の内部構造**

```dart
// ── State ──────────────────────────────
class TodoListState { ... }

// ── ViewModel ──────────────────────────
class TodoListNotifier extends Notifier<TodoListState> { ... }

// ── Provider（DI 登録） ────────────────
final todoListProvider = NotifierProvider<TodoListNotifier, TodoListState>(
  TodoListNotifier.new,
);
```

State / Notifier / Provider は密結合のため同一ファイルにまとめる。これが Flutter コミュニティの慣習。

---

## 8. テスト戦略

### 各層のテスト対象

| 層 | テスト対象 | 手法 |
|---|---|---|
| Domain | Entity のロジック（`copyWith` 等）| Unit Test |
| Data | Repository 実装 | Integration Test（実 DB）|
| ViewModel | Notifier のビジネスロジック | Unit Test + `ProviderContainer` |
| View | Widget の描画 | Widget Test（Mock Repository を注入）|

### Notifier のテスト例

```dart
test('toggle で isCompleted が反転する', () async {
  final container = ProviderContainer(
    overrides: [
      todoRepositoryProvider.overrideWithValue(InMemoryTodoRepository()),
    ],
  );

  final notifier = container.read(todoListProvider.notifier);
  await notifier.add('テスト');
  await notifier.toggle(id);

  final todos = container.read(todoListProvider);
  expect(todos.first.isCompleted, isTrue);
});
```

---

## 9. 原則まとめ

1. **依存は内側に向ける**: Presentation → Domain ← Data
2. **UI は state の関数**: `build()` に副作用を持ち込まない
3. **単方向データフロー**: データは引数で下に、イベントはコールバックで上に
4. **状態の種類を分ける**: ビジネス状態は ViewModel、UI ローカル状態は Widget
5. **DI で差し替え可能にする**: Singleton を使わず、Interface + Riverpod Provider で管理
6. **context の使用を制限する**: `Theme.of` 以外は Widget 層で呼ばない
7. **Page が唯一の Riverpod 接触点**: `ref.watch()` は Page 層に閉じ込める
