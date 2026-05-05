import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/todo.dart';
import '../providers/todo_providers.dart';
import 'priority_badge.dart';

class TodoListItem extends ConsumerWidget {
  const TodoListItem({super.key, required this.todo});
  final Todo todo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(todo.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('削除の確認'),
          content: Text('「${todo.title}」を削除しますか？'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('キャンセル')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('削除')),
          ],
        ),
      ),
      onDismissed: (_) => ref.read(todoListProvider.notifier).delete(todo.id),
      child: ListTile(
        leading: Checkbox(
          value: todo.isCompleted,
          onChanged: (_) => ref.read(todoListProvider.notifier).toggle(todo),
        ),
        title: Text(
          todo.title,
          style: todo.isCompleted
              ? const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)
              : null,
        ),
        subtitle: todo.description.isNotEmpty
            ? Text(todo.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey))
            : null,
        trailing: PriorityBadge(priority: todo.priority),
        onTap: () => context.push('/todo/${todo.id}', extra: todo),
      ),
    );
  }
}
