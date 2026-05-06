import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../todo_list_provider.dart';
import '../widgets/todo_list.dart';

class TodoListPage extends ConsumerWidget {
  const TodoListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(todoListProvider);
    final notifier = ref.read(todoListProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('TODO リスト'),
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (state) => TodoList(
          todos: state.filteredTodos,
          selectedFilter: state.filter,
          onFilterChange: notifier.changeFilter,
          onToggle: notifier.toggle,
          onDelete: notifier.delete,
          onTap: (id) => context.push('/todos/$id'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        tooltip: '追加',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    try {
      final title = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Todo を追加'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'タイトルを入力'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('追加'),
            ),
          ],
        ),
      );
      if (title != null && title.isNotEmpty) {
        await ref.read(todoListProvider.notifier).add(title);
      }
    } finally {
      controller.dispose();
    }
  }
}
