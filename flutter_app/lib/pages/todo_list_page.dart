import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/todo.dart';
import '../repositories/todo_repository.dart';
import '../widgets/todo_list.dart';

const _uuid = Uuid();

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final _repo = TodoRepository.instance;
  List<Todo> _todos = [];
  TodoFilter _filter = TodoFilter.all;
  bool _loading = true;

  List<Todo> get _filteredTodos => switch (_filter) {
        TodoFilter.all => _todos,
        TodoFilter.active => _todos.where((t) => !t.isCompleted).toList(),
        TodoFilter.completed => _todos.where((t) => t.isCompleted).toList(),
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final todos = await _repo.findAll();
    setState(() {
      _todos = todos;
      _loading = false;
    });
  }

  Future<void> _toggle(String id) async {
    final todo = _todos.firstWhere((t) => t.id == id);
    final updated = todo.copyWith(isCompleted: !todo.isCompleted);
    await _repo.update(updated);
    setState(() {
      _todos = _todos.map((t) => t.id == id ? updated : t).toList();
    });
  }

  Future<void> _add(String title) async {
    final todo = Todo(
      id: _uuid.v4(),
      title: title,
      createdAt: DateTime.now(),
    );
    await _repo.insert(todo);
    setState(() => _todos = [..._todos, todo]);
  }

  Future<void> _delete(String id) async {
    await _repo.delete(id);
    setState(() => _todos = _todos.where((t) => t.id != id).toList());
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TodoList(
              todos: _filteredTodos,
              selectedFilter: _filter,
              onFilterChange: _onFilterChange,
              onToggle: _toggle,
              onDelete: _delete,
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        tooltip: '追加',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Todo を追加'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'タイトルを入力'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('追加'),
          ),
        ],
      ),
    );
    if (title != null && title.isNotEmpty) await _add(title);
  }
}
