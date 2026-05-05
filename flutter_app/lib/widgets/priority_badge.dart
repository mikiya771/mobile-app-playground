import 'package:flutter/material.dart';
import '../models/todo.dart';

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});

  final TodoPriority priority;

  static const _labels = {
    TodoPriority.low: '低',
    TodoPriority.medium: '中',
    TodoPriority.high: '高',
  };
  static const _colors = {
    TodoPriority.low: Colors.green,
    TodoPriority.medium: Colors.orange,
    TodoPriority.high: Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final label = _labels[priority]!;
    final color = _colors[priority]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
