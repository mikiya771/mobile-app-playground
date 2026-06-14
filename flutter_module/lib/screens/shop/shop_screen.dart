import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../channels/navigation_channel.dart';
import '../../store/app_store.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);
    final sharedCounter = ref.watch(sharedCounterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
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
          // Cart + shared counter — both readable and writable from this branch.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cart (shared across branches)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Text(
                        '$cartCount items',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove_shopping_cart),
                        onPressed: cartCount > 0
                            ? () => ref.read(cartCountProvider.notifier).state--
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart),
                        onPressed: () =>
                            ref.read(cartCountProvider.notifier).state++,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
            'Products',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final id in ['42', '43', '44', '45'])
            ListTile(
              leading: const Icon(Icons.storefront),
              title: Text('Product #$id'),
              subtitle: Text('Deep-link: sampleapp://shop/$id'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/shop/$id'),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: const Text('Open Native Screen (Flutter→Native)'),
            subtitle: const Text('Demonstrates the Flutter→native call path'),
            onTap: () => NavigationChannelController.instance
                .openNativeScreen('nativeDetail', {'from': 'shop'}),
          ),
        ],
      ),
    );
  }
}
