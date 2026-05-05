import 'package:flutter/material.dart';
import '../models/todo.dart';

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});
  final TodoPriority priority;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      TodoPriority.high => Colors.red,
      TodoPriority.medium => Colors.orange,
      TodoPriority.low => Colors.green,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        priority.label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
