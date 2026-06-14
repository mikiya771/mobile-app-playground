import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'channels/navigation_channel.dart';
import 'router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Create the router first, then give it to the channel controller so
  // MethodChannel callbacks can drive navigation without needing a BuildContext.
  final router = createRouter();
  NavigationChannelController.initialize(router);

  runApp(
    // ProviderScope holds all Riverpod state. Because there is exactly one
    // FlutterEngine and one Dart isolate, this single ProviderScope is shared
    // by both the Search and Shop branches — proving acceptance criterion #3.
    ProviderScope(
      child: MaterialApp.router(
        title: 'Add-to-App Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        routerConfig: router,
      ),
    ),
  );
}
