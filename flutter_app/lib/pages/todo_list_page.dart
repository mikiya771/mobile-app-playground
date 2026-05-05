import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../widgets/todo_list.dart';

// ダミーデータ（Step 8 で Riverpod の AsyncNotifier に置き換える）
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
