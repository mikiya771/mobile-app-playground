import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/todo_repository.dart';
import '../repositories/todo_repository_interface.dart';

final todoRepositoryProvider = Provider<TodoRepositoryInterface>((ref) {
  return TodoRepository();
});
