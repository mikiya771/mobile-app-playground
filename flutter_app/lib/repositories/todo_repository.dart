import '../api/todo_api.dart';
import '../db/todo_database.dart';
import '../models/todo.dart';

class TodoRepository {
  final _db = TodoDatabase();
  final _api = TodoApi();

  Future<List<Todo>> getAll() => _db.getAll();
  Future<void> add(Todo todo) => _db.insert(todo);
  Future<void> update(Todo todo) => _db.update(todo);
  Future<void> delete(String id) => _db.delete(id);

  Future<void> syncFromApi() async {
    final todos = await _api.fetchTodos();
    await _db.insertAllIfAbsent(todos);
  }
}
