# Flutter 質疑まとめ

学習中に出た疑問と回答の記録。

---

## BuildContext とは何か

**Q: `build(BuildContext context)` の `context` って何？**

ウィジェットツリー上の「自分の位置情報」。Flutter が `build()` を呼ぶときに自動で渡してくる。

主な用途：
- `Theme.of(context)` — ツリーを上に向かって探し、最初に見つかった Theme を取得
- `Navigator.of(context)` — 画面遷移
- `MediaQuery.of(context)` — 画面サイズ取得

React の `useContext()` を自動で呼んでくれるイメージ。

**注意: `initState()` の中では使えない**

```dart
@override
void initState() {
  super.initState();
  final theme = Theme.of(context); // ❌ まだツリーに入っていないのでエラー
}

@override
Widget build(BuildContext context) {
  final theme = Theme.of(context); // ✅ build() の中は安全
}
```

---

## context の使用ルール

**Q: できるかぎり下から上位へのアクセスはないほうがいいと思うが、Flutter ではどうか？**

`Theme.of(context)` だけ許容し、それ以外の context 経由アクセスはウィジェット層では使わない。

| アクセス方法 | ウィジェット層 | ページ層 |
|---|---|---|
| `Theme.of(context)` | ✅ 許容 | ✅ 許容 |
| `MediaQuery.of(context)` | ❌ 引数で渡す | ✅ 許容 |
| `Navigator` / `context.go()` | ❌ コールバックで渡す | ✅ 許容 |
| `ScaffoldMessenger.of(context)` | ❌ | ✅ 許容 |

`Theme.of(context)` を許容する理由: Flutter のレンダリング基盤と不可分で、代替手段がほぼないため。

---

## デザインとレイアウトの分離

**Q: HTML と CSS のようにデザインと構造を分離できないか？**

Flutter は両方をウィジェットで表現するため、**完全な分離は構造上できない**。

近い分離を実現する手段：

| 手段 | 内容 |
|---|---|
| `ThemeData` + `TextTheme` | 色・フォントサイズを一元管理。CSS変数に近い |
| 定数クラス（`AppTextStyles` など） | `context` 不要なスタイル定数。ダークモード対応は不可 |
| `ThemeExtension` | カスタムデザイントークン。定義量が増えがち |

現実的な落とし所は「マジックナンバーを定数ファイルに逃がす」程度。

---

## 状態管理の方針

**Q: state は常にページ層で持ちたい。Riverpod のような useContext 的な仕組みは必要か？**

必ずしも不要。状態の種類によって判断する。

| 状態の種類 | 例 | 置き場所 |
|---|---|---|
| UIローカル状態 | ドロップダウン開閉・アニメーション | ウィジェット自身（`StatefulWidget`） |
| データ・ビジネス状態 | Todoリスト・フィルター選択・認証 | ページ層 → 引数で流す |

**このプロジェクトの方針:**
- prop drilling を基本とする
- ページ層の `StatefulWidget` + `setState` で状態管理
- データは引数で下に流し、イベントはコールバックで上に返す
- Riverpod は導入しない（非同期・横断的な状態が genuinely 必要になった時点で判断）

---

## Notifier（ViewModel）と Page の関係

**Q: Notifier は ViewModel でしょ。ViewModel なら必ず1ページに紐づくのでは？ 1つの VM が複数ページに紐づくのはよくわからない。**

「1 Page : 1 Notifier」が基本形で正しい。例外は「ページをまたいで同期が必要な状態」のときだけ。

**基本形（ほとんどのケース）**
```
TodoListPage  ←→  TodoListNotifier
LoginPage     ←→  LoginNotifier
ProfilePage   ←→  ProfileNotifier
```

**例外: アプリ横断の共有状態**

認証状態は複数ページが同じ値を参照する必要がある:

```
AuthNotifier
  ├── LoginPage（ログイン操作・ローディング表示）
  ├── ProfilePage（ユーザー名表示・ログアウト）
  └── AppBar（アバター表示）
```

`AuthNotifier` を LoginPage 専用にしてしまうと、ProfilePage が「誰がログインしているか」を知る手段がなくなる。

**判断基準**

| 状態の性質 | パターン |
|---|---|
| このページでしか使わない | 1 Page : 1 Notifier |
| ページをまたいで共有・同期が必要 | 1 Notifier : N Pages |

---

## 画面回転・バックグラウンドでの状態保持

**Q: 画面回転やバックグラウンドから戻ってきても ViewModel は破棄されず状態は保たれる？**

はい。Riverpod の Provider は `ProviderScope`（アプリ起動時に1回だけ生成）が保持するため、ウィジェットツリーの再構築と無関係に生き続ける。

```
ProviderScope（アプリ起動時に1回だけ生成、ここに Provider のインスタンスが存在）
  └── MyApp
        └── TodoListPage（回転で rebuild されても...）
              └── ref.watch(todoListProvider) → 同じインスタンスを参照
```

`StatefulWidget` の `State` はウィジェットが破棄されると消えるが、Riverpod の Provider はそうならない。

| 状況 | 状態 |
|---|---|
| 画面回転 | 保持される |
| バックグラウンド → 復帰 | 保持される |
| アプリ完全終了 → 再起動 | **消える** |

再起動後の復元には sqflite 等の永続化 + `build()` での読み直しが必要（現在の実装はこの方式）。

---

## Riverpod と React のアナロジー

**Q: Riverpod の `ref.watch` は React の `useState` と `useContext` どちらに近い？**

`useContext` + Context API に対応する。

| React | Flutter/Riverpod |
|---|---|
| `useState` | `StatefulWidget` の `setState` |
| `useContext` + Context API | `ref.watch(provider)` |
| Context.Provider | `ProviderScope` + `Provider` |

- ページ内だけで閉じる状態（ドロップダウン開閉など）→ `StatefulWidget`（useState 相当）
- フィーチャー全体・複数ページにまたがる状態（Todo リスト・認証など）→ `ref.watch(provider)`（useContext 相当）

---

## ディレクトリ構成: layer-first vs feature-first

**Q: Riverpod を使うときの標準的なディレクトリ構成は？**

Flutter コミュニティでは **feature-first** が主流。

**layer-first（以前の構成）**
```
lib/
  models/
  repositories/
  providers/
  notifiers/
  pages/
  widgets/
```
機能を一つ追加するたびに複数フォルダをまたいで変更が発生する。

**feature-first（現在の構成）**
```
lib/
  features/
    todo/
      todo.dart                    # Entity
      todo_repository_interface.dart
      todo_repository.dart
      todo_repository_provider.dart
      todo_list_provider.dart      # State + Notifier + Provider を一本化
      pages/
      widgets/
```
一つの機能の変更が `features/todo/` 以下に収まる。

**`todo_list_provider.dart` に State・Notifier・Provider を同居させる理由**

この3つは密結合（State の型を知らないと Notifier は書けない・Provider は Notifier の型が必要）なので分割するメリットがない。Flutter コミュニティの慣習でもある。

---

## ListView.separated の API 設計

**Q: `itemCount` と builder 関数を渡す設計がいまいちに感じる。なぜこうなっているか？**

遅延評価（画面に見えている分しか描画しない）を実現するための設計。

- `itemCount` を別に渡す理由: 全アイテムを作らずにスクロールバーの位置（全体の高さ）を計算するため
- `itemBuilder` を渡す理由: 「全部作ってから渡す」ではなく「必要なときだけ作る」ため

件数が少ない場合は `ListView(children: [...])` で直感的に書ける。

```dart
// 直感的だが全件を最初に作る
ListView(
  children: todos.map((t) => TodoCard(todo: t)).toList(),
)

// 遅延評価。大量データ・無限スクロール向け
ListView.separated(
  itemCount: todos.length,
  itemBuilder: (context, index) => TodoCard(todo: todos[index]),
  separatorBuilder: (context, index) => const SizedBox(height: 8),
)
```

| | `ListView(children)` | `ListView.separated` |
|---|---|---|
| 直感的さ | ◎ | △ |
| 遅延描画 | ❌ 全件作る | ✅ 表示分だけ |
| 使いどころ | 数十件以下 | 件数が多い・無限スクロール |
