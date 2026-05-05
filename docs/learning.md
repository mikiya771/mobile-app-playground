# Flutter 学習ノート（読み物）

外出先でも読める概念まとめ。手を動かす課題は `exercises.md` を参照。

---

## 進捗

- [x] Step 1: main.dart を読んでWidgetツリーを理解する
- [x] Step 2: StatelessWidget / StatefulWidget の違いを体感する
- [ ] Step 3: レイアウトWidget（Column / Row / Container）を触る
- [ ] Step 4: モデルクラス Todo を作る
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

## セットアップメモ

- プロジェクト: `flutter_app/`（`--platforms ios,android` で作成）
- iOSシミュレーター: iPhone 16（UDID: `1787F496-6762-4418-A152-FFD0073FBD32`）
- Androidエミュレーター: Pixel 9 API 36（`emulator-5554`）
- 起動: IntelliJから（File → Invalidate Caches 後に安定）
- Hot Reload: IntelliJ のファイル保存（Cmd+S）で自動反映
- エラー「Entrypoint isn't within the current project」→ File → Invalidate Caches → Invalidate and Restart で解消
