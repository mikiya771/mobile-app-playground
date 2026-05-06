import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/pages/login_page.dart';
import 'features/todo/pages/todo_list_page.dart';
import 'features/todo/pages/todo_detail_page.dart';

// authProvider の変化を GoRouter に伝えるアダプター
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authProvider, (previous, next) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);

  final router = GoRouter(
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final isLoggedIn =
          ref.read(authProvider).valueOrNull?.isLoggedIn ?? false;
      final isOnLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !isOnLogin) return '/login';
      if (isLoggedIn && isOnLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const TodoListPage(),
      ),
      GoRoute(
        path: '/todos/:id',
        builder: (context, state) =>
            TodoDetailPage(todoId: state.pathParameters['id']!),
      ),
    ],
  );

  ref.onDispose(() {
    refreshNotifier.dispose();
    router.dispose();
  });

  return router;
});
