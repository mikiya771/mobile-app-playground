import 'todo.dart';

abstract class TodoRepositoryInterface {
  Future<List<Todo>> findAll();
  Future<void> insert(Todo todo);
  Future<void> update(Todo todo);
  Future<void> delete(String id);
}
