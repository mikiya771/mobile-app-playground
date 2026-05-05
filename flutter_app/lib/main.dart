import 'package:flutter/material.dart';
import 'models/todo.dart';

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
      home: const TodoListPage(),
    );
  }
}

// ── ダミーデータ ─────────────────────────────────────────────────────────────
final _dummyTodos = [
  Todo(
    id: '1',
    title: '牛乳を買う',
    description: '近くのスーパーでセール中',
    priority: TodoPriority.low,
    createdAt: DateTime(2025, 5, 1),
  ),
  Todo(
    id: '2',
    title: 'Flutter を学ぶ',
    description: 'Step 4: モデルクラスを作る',
    priority: TodoPriority.high,
    createdAt: DateTime(2025, 5, 2),
  ),
  Todo(
    id: '3',
    title: '部屋を掃除する',
    description: '',
    priority: TodoPriority.medium,
    isCompleted: true,
    createdAt: DateTime(2025, 5, 3),
  ),
];

// ── ページ ───────────────────────────────────────────────────────────────────
class TodoListPage extends StatelessWidget {
  const TodoListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('TODO リスト'),
      ),
      body: TodoList(todos: _dummyTodos),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: '追加',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ── TODO リスト ──────────────────────────────────────────────────────────────
class TodoList extends StatelessWidget {
  const TodoList({super.key, required this.todos});

  final List<Todo> todos;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const FilterTabBar(),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: todos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => TodoCard(todo: todos[index]),
          ),
        ),
      ],
    );
  }
}

// ── フィルタータブ ────────────────────────────────────────────────────────────
class FilterTabBar extends StatelessWidget {
  const FilterTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: FilterChipButton(label: 'すべて', isSelected: true)),
          const SizedBox(width: 8),
          Expanded(child: FilterChipButton(label: '未完了', isSelected: false)),
          const SizedBox(width: 8),
          Expanded(child: FilterChipButton(label: '完了', isSelected: false)),
        ],
      ),
    );
  }
}

class FilterChipButton extends StatelessWidget {
  const FilterChipButton({
    super.key,
    required this.label,
    required this.isSelected,
  });

  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

// ── TODO カード ───────────────────────────────────────────────────────────────
class TodoCard extends StatelessWidget {
  const TodoCard({super.key, required this.todo});

  final Todo todo;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              todo.isCompleted
                  ? Icons.check_box
                  : Icons.check_box_outline_blank,
              color: todo.isCompleted
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todo.title,
                    style: TextStyle(
                      fontSize: 16,
                      decoration: todo.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: todo.isCompleted
                          ? Theme.of(context).colorScheme.outline
                          : null,
                    ),
                  ),
                  if (todo.description.isNotEmpty)
                    Text(
                      todo.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PriorityBadge(priority: todo.priority),
          ],
        ),
      ),
    );
  }
}

// ── 優先度バッジ ──────────────────────────────────────────────────────────────
class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});

  final TodoPriority priority;

  // 優先度 → 表示ラベル・色のマッピングはUIレイヤーで持つ（モデルはFlutterに依存しない）
  static const _labels = {
    TodoPriority.low: '低',
    TodoPriority.medium: '中',
    TodoPriority.high: '高',
  };
  static const _colors = {
    TodoPriority.low: Colors.green,
    TodoPriority.medium: Colors.orange,
    TodoPriority.high: Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final label = _labels[priority]!;
    final color = _colors[priority]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
