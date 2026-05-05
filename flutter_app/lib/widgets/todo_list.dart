import 'package:flutter/material.dart';
import '../models/todo.dart';
import 'filter_tab_bar.dart';
import 'todo_card.dart';

class TodoList extends StatelessWidget {
  const TodoList({super.key, required this.todos});

  final List<Todo> todos;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const FilterTabBar(),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: todos.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) => TodoCard(todo: todos[index]),
          ),
        ),
      ],
    );
  }
}
