import 'package:flutter/material.dart';
import '../models/todo.dart';
import 'priority_badge.dart';

class TodoCard extends StatelessWidget {
  const TodoCard({super.key, required this.todo, required this.onToggle});

  final Todo todo;
  final void Function(String id) onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => onToggle(todo.id),
              child: Icon(
                todo.isCompleted
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                color: todo.isCompleted
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todo.title,
                    style: TextStyle(
                      fontSize: 16,
                      decoration: todo.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: todo.isCompleted
                          ? Theme.of(context).colorScheme.outline
                          : null,
                    ),
                  ),
                  if (todo.description.isNotEmpty)
                    Text(
                      todo.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PriorityBadge(priority: todo.priority),
          ],
        ),
      ),
    );
  }
}
