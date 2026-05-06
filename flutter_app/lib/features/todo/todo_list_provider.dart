import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'todo.dart';
import 'todo_repository_interface.dart';
import 'todo_repository_provider.dart';

const _uuid = Uuid();

// ── State ────────────────────────────────────────────────────────────────────
class TodoListState {
  const TodoListState({
    this.todos = const [],
    this.filter = TodoFilter.all,
    this.loading = true,
  });

  final List<Todo> todos;
  final TodoFilter filter;
  final bool loading;

  List<Todo> get filteredTodos => switch (filter) {
        TodoFilter.all => todos,
        TodoFilter.active => todos.where((t) => !t.isCompleted).toList(),
        TodoFilter.completed => todos.where((t) => t.isCompleted).toList(),
      };

  TodoListState copyWith({
    List<Todo>? todos,
    TodoFilter? filter,
    bool? loading,
  }) =>
      TodoListState(
        todos: todos ?? this.todos,
        filter: filter ?? this.filter,
        loading: loading ?? this.loading,
      );
}

// ── ViewModel ────────────────────────────────────────────────────────────────
class TodoListNotifier extends Notifier<TodoListState> {
  late final TodoRepositoryInterface _repo;

  @override
  TodoListState build() {
    _repo = ref.read(todoRepositoryProvider);
    _load();
    return const TodoListState();
  }

  Future<void> _load() async {
    final todos = await _repo.findAll();
    state = state.copyWith(todos: todos, loading: false);
  }

  Future<void> toggle(String id) async {
    final todo = state.todos.firstWhere((t) => t.id == id);
    final updated = todo.copyWith(isCompleted: !todo.isCompleted);
    await _repo.update(updated);
    state = state.copyWith(
      todos: state.todos.map((t) => t.id == id ? updated : t).toList(),
    );
  }

  Future<void> add(String title) async {
    final todo = Todo(
      id: _uuid.v4(),
      title: title,
      createdAt: DateTime.now(),
    );
    await _repo.insert(todo);
    state = state.copyWith(todos: [...state.todos, todo]);
  }

  Future<void> edit(
    String id, {
    required String title,
    required String description,
    required TodoPriority priority,
  }) async {
    final todo = state.todos.firstWhere((t) => t.id == id);
    final updated = todo.copyWith(
      title: title,
      description: description,
      priority: priority,
    );
    await _repo.update(updated);
    state = state.copyWith(
      todos: state.todos.map((t) => t.id == id ? updated : t).toList(),
    );
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    state = state.copyWith(
      todos: state.todos.where((t) => t.id != id).toList(),
    );
  }

  void changeFilter(TodoFilter filter) {
    state = state.copyWith(filter: filter);
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────
final todoListProvider =
    NotifierProvider<TodoListNotifier, TodoListState>(TodoListNotifier.new);
