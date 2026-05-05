import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../widgets/todo_list.dart';

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
    description: 'Step 5: インタラクションを追加する',
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

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  List<Todo> _todos = _dummyTodos;
  TodoFilter _filter = TodoFilter.all;

  List<Todo> get _filteredTodos => switch (_filter) {
    TodoFilter.all       => _todos,
    TodoFilter.active    => _todos.where((t) => !t.isCompleted).toList(),
    TodoFilter.completed => _todos.where((t) => t.isCompleted).toList(),
  };

  void _toggle(String id) {
    setState(() {
      _todos = _todos
          .map((t) => t.id == id ? t.copyWith(isCompleted: !t.isCompleted) : t)
          .toList();
    });
  }

  void _onFilterChange(TodoFilter filter) {
    setState(() => _filter = filter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('TODO リスト'),
      ),
      body: TodoList(
        todos: _filteredTodos,
        selectedFilter: _filter,
        onFilterChange: _onFilterChange,
        onToggle: _toggle,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: '追加',
        child: const Icon(Icons.add),
      ),
    );
  }
}
