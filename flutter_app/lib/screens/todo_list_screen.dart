import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';
import '../providers/todo_providers.dart';
import '../widgets/todo_list_item.dart';

class TodoListScreen extends ConsumerWidget {
  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(filteredTodosProvider);
    final filter = ref.watch(todoFilterProvider);
    final isSyncing = ref.watch(todoListProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TODO'),
        actions: [
          if (isSyncing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'API同期',
              onPressed: () => ref.read(todoListProvider.notifier).syncFromApi(),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ログアウト',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _FilterBar(current: filter),
        ),
      ),
      body: todos.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text('エラー: $e'),
              TextButton(
                onPressed: () => ref.invalidate(todoListProvider),
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('TODOがありません'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) => TodoListItem(todo: list[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.current});
  final TodoFilter current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: TodoFilter.values.map((f) {
          final label = switch (f) {
            TodoFilter.all => 'すべて',
            TodoFilter.active => '未完了',
            TodoFilter.completed => '完了',
          };
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(label),
              selected: current == f,
              onSelected: (_) =>
                  ref.read(todoFilterProvider.notifier).state = f,
            ),
          );
        }).toList(),
      ),
    );
  }
}
