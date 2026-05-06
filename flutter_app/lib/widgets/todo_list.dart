import 'package:flutter/material.dart';
import '../models/todo.dart';
import 'filter_tab_bar.dart';
import 'todo_card.dart';

class TodoList extends StatelessWidget {
  const TodoList({
    super.key,
    required this.todos,
    required this.selectedFilter,
    required this.onFilterChange,
    required this.onToggle,
    required this.onDelete,
  });

  final List<Todo> todos;
  final TodoFilter selectedFilter;
  final void Function(TodoFilter) onFilterChange;
  final void Function(String id) onToggle;
  final void Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FilterTabBar(
          selectedFilter: selectedFilter,
          onFilterChange: onFilterChange,
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: todos.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) => TodoCard(
              todo: todos[index],
              onToggle: onToggle,
              onDelete: onDelete,
            ),
          ),
        ),
      ],
    );
  }
}
