import 'package:go_router/go_router.dart';

import '../channels/navigation_channel.dart';
import '../screens/search/search_screen.dart';
import '../screens/search/search_detail_screen.dart';
import '../screens/shop/shop_screen.dart';
import '../screens/shop/shop_detail_screen.dart';

/// Creates the app router.
///
/// Architecture note:
///   - StatefulShellRoute.indexedStack hosts 2 branches (Search / Shop).
///   - The shell builder renders ONLY the IndexedStack — no BottomNavigationBar.
///     The native tab bar is the single source of truth for tab UI.
///   - Each branch has a path-prefix (/search, /shop) so that `router.go()`
///     with a deep-link path automatically selects the correct branch.
GoRouter createRouter() {
  final router = GoRouter(
    initialLocation: '/search',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // Give the channel controller a reference to the shell so it can call
          // goBranch() when native sends setBranch.
          NavigationChannelController.instance.updateShell(navigationShell);
          // Return the shell itself — it IS the IndexedStack widget.
          // No Flutter-side bottom navigation bar is rendered here.
          return navigationShell;
        },
        branches: [
          // Branch 0 — Search tab (native tab index 1)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
                routes: [
                  GoRoute(
                    // /search/:id — detail pushed within the Search branch
                    path: ':id',
                    builder: (context, state) => SearchDetailScreen(
                      id: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Branch 1 — Shop tab (native tab index 3)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shop',
                builder: (context, state) => const ShopScreen(),
                routes: [
                  GoRoute(
                    // /shop/:id — detail pushed within the Shop branch
                    path: ':id',
                    builder: (context, state) => ShopDetailScreen(
                      id: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );

  // Report depth to native on every route change so Android can decide
  // whether to delegate back presses to Flutter or handle natively.
  router.routerDelegate.addListener(() => _reportDepth(router));

  return router;
}

void _reportDepth(GoRouter router) {
  // currentConfiguration is typed as RouteMatchList? from RouterDelegate<T>.
  final config = router.routerDelegate.currentConfiguration;
  if (config == null) return;
  final path = config.uri.path;
  final segments = path.split('/').where((s) => s.isNotEmpty).toList();

  final int branchIndex;
  if (path.startsWith('/search')) {
    branchIndex = 0;
  } else if (path.startsWith('/shop')) {
    branchIndex = 1;
  } else {
    return;
  }

  // depth: /search = 1 (root), /search/42 = 2 (detail)
  NavigationChannelController.instance.reportBranchStackChange(branchIndex, segments.length);
}
