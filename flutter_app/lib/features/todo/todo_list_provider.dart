import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'todo.dart';
import 'todo_repository.dart';
import 'todo_repository_interface.dart';
import 'todo_repository_provider.dart';

const _uuid = Uuid();

// ── State ────────────────────────────────────────────────────────────────────
class TodoListState {
  const TodoListState({
    this.todos = const [],
    this.filter = TodoFilter.all,
  });

  final List<Todo> todos;
  final TodoFilter filter;

  List<Todo> get filteredTodos => switch (filter) {
        TodoFilter.all => todos,
        TodoFilter.active => todos.where((t) => !t.isCompleted).toList(),
        TodoFilter.completed => todos.where((t) => t.isCompleted).toList(),
      };

  TodoListState copyWith({
    List<Todo>? todos,
    TodoFilter? filter,
  }) =>
      TodoListState(
        todos: todos ?? this.todos,
        filter: filter ?? this.filter,
      );
}

// ── ViewModel ────────────────────────────────────────────────────────────────
class TodoListNotifier extends AsyncNotifier<TodoListState> {
  late final TodoRepositoryInterface _repo;
  late final TodoRepository _repoImpl;

  @override
  Future<TodoListState> build() async {
    _repo = ref.read(todoRepositoryProvider);
    _repoImpl = _repo as TodoRepository;
    final todos = await _repo.findAll();
    return TodoListState(todos: todos);
  }

  Future<void> toggle(String id) async {
    final current = state.requireValue;
    final todo = current.todos.firstWhere((t) => t.id == id);
    final updated = todo.copyWith(isCompleted: !todo.isCompleted);
    await _repo.update(updated);
    state = AsyncData(current.copyWith(
      todos: current.todos.map((t) => t.id == id ? updated : t).toList(),
    ));
  }

  Future<void> add(String title) async {
    final current = state.requireValue;
    final todo = Todo(
      id: _uuid.v4(),
      title: title,
      createdAt: DateTime.now(),
    );
    await _repo.insert(todo);
    state = AsyncData(current.copyWith(todos: [...current.todos, todo]));
  }

  Future<void> edit(
    String id, {
    required String title,
    required String description,
    required TodoPriority priority,
  }) async {
    final current = state.requireValue;
    final todo = current.todos.firstWhere((t) => t.id == id);
    final updated = todo.copyWith(
      title: title,
      description: description,
      priority: priority,
    );
    await _repo.update(updated);
    state = AsyncData(current.copyWith(
      todos: current.todos.map((t) => t.id == id ? updated : t).toList(),
    ));
  }

  Future<void> delete(String id) async {
    final current = state.requireValue;
    await _repo.delete(id);
    state = AsyncData(current.copyWith(
      todos: current.todos.where((t) => t.id != id).toList(),
    ));
  }

  void changeFilter(TodoFilter filter) {
    final current = state.requireValue;
    state = AsyncData(current.copyWith(filter: filter));
  }

  Future<void> sync() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final todos = await _repoImpl.syncFromRemote();
      return TodoListState(todos: todos);
    });
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────
final todoListProvider =
    AsyncNotifierProvider<TodoListNotifier, TodoListState>(TodoListNotifier.new);
