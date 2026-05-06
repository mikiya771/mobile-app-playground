import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../todo.dart';
import '../todo_list_provider.dart';

class TodoDetailPage extends ConsumerWidget {
  const TodoDetailPage({super.key, required this.todoId});

  final String todoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todo = ref
        .watch(todoListProvider)
        .valueOrNull
        ?.todos
        .where((t) => t.id == todoId)
        .firstOrNull;
    final notifier = ref.read(todoListProvider.notifier);

    if (todo == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('詳細'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Web で開く',
            onPressed: () {
              final url = 'https://jsonplaceholder.typicode.com/todos/${todo.id}';
              context.push('/webview?url=${Uri.encodeComponent(url)}');
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDialog(context, todo, notifier),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PriorityChip(priority: todo.priority),
            const SizedBox(height: 16),
            Text(
              todo.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    decoration: todo.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: todo.isCompleted
                        ? Theme.of(context).colorScheme.outline
                        : null,
                  ),
            ),
            if (todo.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                todo.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              '作成日: ${_formatDate(todo.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    Todo todo,
    TodoListNotifier notifier,
  ) async {
    final titleController = TextEditingController(text: todo.title);
    final descController = TextEditingController(text: todo.description);
    var priority = todo.priority;

    try {
      await showDialog<void>(
        context: context,
        builder: (context) => _EditDialog(
          titleController: titleController,
          descController: descController,
          initialPriority: priority,
          onSave: (newPriority) async {
            final title = titleController.text.trim();
            if (title.isEmpty) return;
            await notifier.edit(
              todo.id,
              title: title,
              description: descController.text.trim(),
              priority: newPriority,
            );
            if (context.mounted) Navigator.pop(context);
          },
        ),
      );
    } finally {
      titleController.dispose();
      descController.dispose();
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
}

// ── ウィジェット ──────────────────────────────────────────────────────────────

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});

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
    return Chip(
      label: Text(label, style: TextStyle(color: color)),
      backgroundColor: color.withAlpha(30),
      side: BorderSide(color: color),
    );
  }
}

class _EditDialog extends StatefulWidget {
  const _EditDialog({
    required this.titleController,
    required this.descController,
    required this.initialPriority,
    required this.onSave,
  });

  final TextEditingController titleController;
  final TextEditingController descController;
  final TodoPriority initialPriority;
  final Future<void> Function(TodoPriority) onSave;

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late TodoPriority _priority;

  @override
  void initState() {
    super.initState();
    _priority = widget.initialPriority;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('編集'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widget.titleController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'タイトル'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.descController,
            decoration: const InputDecoration(labelText: '説明'),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<TodoPriority>(
            initialValue: _priority,
            decoration: const InputDecoration(labelText: '優先度'),
            items: const [
              DropdownMenuItem(value: TodoPriority.low, child: Text('低')),
              DropdownMenuItem(value: TodoPriority.medium, child: Text('中')),
              DropdownMenuItem(value: TodoPriority.high, child: Text('高')),
            ],
            onChanged: (v) => setState(() => _priority = v!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () => widget.onSave(_priority),
          child: const Text('保存'),
        ),
      ],
    );
  }
}
