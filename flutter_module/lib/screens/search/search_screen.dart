import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../channels/navigation_channel.dart';
import '../../store/app_store.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);
    final sharedCounter = ref.watch(sharedCounterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        actions: [
          // Cart badge — updated live when Shop branch adds items, proving
          // shared state across branches (acceptance criterion #3).
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: null,
              ),
              if (cartCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      '$cartCount',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Shared counter — visible and editable from both branches.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shared Counter (same engine, same isolate)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '$sharedCounter',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () => ref
                            .read(sharedCounterProvider.notifier)
                            .state--,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => ref
                            .read(sharedCounterProvider.notifier)
                            .state++,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Search Results',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // Sample search results — each opens a detail screen within this branch.
          for (final id in ['alpha', 'beta', 'gamma', 'delta'])
            ListTile(
              leading: const Icon(Icons.search),
              title: Text('Result: $id'),
              subtitle: Text('Tap to push detail (id=$id) — stack preserved on tab switch'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/search/$id'),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: const Text('Open Native Screen (Flutter→Native)'),
            subtitle: const Text('Demonstrates the Flutter→native call path'),
            onTap: () => NavigationChannelController.instance
                .openNativeScreen('nativeDetail', {'from': 'search'}),
          ),
        ],
      ),
    );
  }
}
