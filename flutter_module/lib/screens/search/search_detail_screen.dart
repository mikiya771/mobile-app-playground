import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../store/app_store.dart';

class SearchDetailScreen extends ConsumerWidget {
  final String id;

  const SearchDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);
    final sharedCounter = ref.watch(sharedCounterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Search Detail: $id'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail for "$id"',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            // Shared state visible even from a pushed page.
            Card(
              child: ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('Shared Counter'),
                subtitle: const Text('Mutated from either branch, reflected everywhere'),
                trailing: Text(
                  '$sharedCounter',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.shopping_cart_outlined),
                title: const Text('Cart Count (from Shop branch)'),
                trailing: Text(
                  '$cartCount',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            const Spacer(),
            // Stack depth indicator helps verify criterion #1 during testing.
            Center(
              child: Text(
                'Stack depth: 2 (detail pushed in Search branch)\n'
                'Switch to Shop then back — this page should still be here.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
