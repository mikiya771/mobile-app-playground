import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Step 2: Widget の分解'),
    );
  }
}

// ── StatefulWidget ──────────────────────────────────────────────────────────
// 状態（_counter）を持つ。setState() で build() を再実行する。
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _increment() => setState(() => _counter++);
  void _decrement() => setState(() => _counter--);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // StatelessWidget に「値」だけ渡す。
            // ここを変えても CounterDisplay は setState() を知らない。
            CounterDisplay(count: _counter),
            const SizedBox(height: 24),
            CounterLabel(text: '上▲ or 下▼ボタンで変えてみて'),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _increment,
            tooltip: 'Increment',
            heroTag: 'inc',
            child: const Icon(Icons.arrow_upward),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            onPressed: _decrement,
            tooltip: 'Decrement',
            heroTag: 'dec',
            child: const Icon(Icons.arrow_downward),
          ),
        ],
      ),
    );
  }
}

// ── StatelessWidget ─────────────────────────────────────────────────────────
// 状態を持たない。外から渡された count を表示するだけ。
// setState() を呼ぶ手段がないので、自分では再描画できない。
class CounterDisplay extends StatelessWidget {
  const CounterDisplay({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$count',
      style: Theme.of(context).textTheme.displayLarge,
    );
  }
}

// ラベルも StatelessWidget にしてみる（テキストが変わらないなら StatelessWidget でいい）
class CounterLabel extends StatelessWidget {
  const CounterLabel({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
