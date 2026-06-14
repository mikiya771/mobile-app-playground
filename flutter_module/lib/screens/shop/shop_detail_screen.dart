import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../store/app_store.dart';

class ShopDetailScreen extends ConsumerWidget {
  final String id;

  const ShopDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);
    final sharedCounter = ref.watch(sharedCounterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Product #$id'),
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
              'Product detail for #$id',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Deep-link: sampleapp://shop/$id',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('Shared Counter'),
                subtitle: const Text('Changes visible in Search branch immediately'),
                trailing: Text(
                  '$sharedCounter',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.shopping_cart),
                title: const Text('Cart Count'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$cartCount',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Add to Cart'),
                      onPressed: () =>
                          ref.read(cartCountProvider.notifier).state++,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Center(
              child: Text(
                'Stack depth: 2 (detail pushed in Shop branch)\n'
                'Switch to Search then back — this page should still be here.',
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
