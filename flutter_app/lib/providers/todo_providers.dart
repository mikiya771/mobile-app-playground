import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo.dart';
import '../repositories/todo_repository.dart';

final todoRepositoryProvider = Provider((_) => TodoRepository());

final todoListProvider = AsyncNotifierProvider<TodoListNotifier, List<Todo>>(
  TodoListNotifier.new,
);

class TodoListNotifier extends AsyncNotifier<List<Todo>> {
  @override
  Future<List<Todo>> build() => ref.read(todoRepositoryProvider).getAll();

  Future<void> add(Todo todo) async {
    await ref.read(todoRepositoryProvider).add(todo);
    ref.invalidateSelf();
  }

  Future<void> updateTodo(Todo todo) async {
    await ref.read(todoRepositoryProvider).update(todo);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await ref.read(todoRepositoryProvider).delete(id);
    ref.invalidateSelf();
  }

  Future<void> toggle(Todo todo) => updateTodo(todo.copyWith(isCompleted: !todo.isCompleted));

  Future<void> syncFromApi() async {
    state = const AsyncLoading();
    try {
      await ref.read(todoRepositoryProvider).syncFromApi();
    } catch (e, st) {
      state = AsyncError(e, st);
      return;
    }
    ref.invalidateSelf();
  }
}

enum TodoFilter { all, active, completed }

final todoFilterProvider = StateProvider((_) => TodoFilter.all);

final filteredTodosProvider = Provider<AsyncValue<List<Todo>>>((ref) {
  final todos = ref.watch(todoListProvider);
  final filter = ref.watch(todoFilterProvider);
  return todos.whenData((list) => switch (filter) {
        TodoFilter.all => list,
        TodoFilter.active => list.where((t) => !t.isCompleted).toList(),
        TodoFilter.completed => list.where((t) => t.isCompleted).toList(),
      });
});
