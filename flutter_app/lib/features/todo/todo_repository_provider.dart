import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'todo_repository_interface.dart';
import 'todo_repository.dart';

final todoRepositoryProvider = Provider<TodoRepositoryInterface>((ref) {
  return TodoRepository();
});
