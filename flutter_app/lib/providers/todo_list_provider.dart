import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifiers/todo_list_notifier.dart';

final todoListProvider =
    NotifierProvider<TodoListNotifier, TodoListState>(TodoListNotifier.new);
