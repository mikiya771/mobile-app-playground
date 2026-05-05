import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/todo.dart';
import '../providers/auth_providers.dart';
import '../screens/login_screen.dart';
import '../screens/login_webview_screen.dart';
import '../screens/todo_list_screen.dart';
import '../screens/todo_detail_webview_screen.dart';
import '../screens/todo_form_screen.dart';

// GoRouter の refresh 用 ChangeNotifier
class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(Ref ref) {
    ref.listen<AsyncValue<String?>>(authProvider, (prev, next) {
      if (prev?.valueOrNull != next.valueOrNull) notifyListeners();
    });
  }
}

final _authRouterNotifierProvider = ChangeNotifierProvider(
  (ref) => _AuthRouterNotifier(ref),
);

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_authRouterNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      if (auth.isLoading) return null;

      final isLoggedIn = auth.valueOrNull != null;
      final isLoginRoute = state.matchedLocation.startsWith('/login');

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (ctx, s) => const LoginScreen(),
        routes: [
          GoRoute(
            path: 'webview',
            builder: (ctx, s) => const LoginWebViewScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/',
        builder: (ctx, s) => const TodoListScreen(),
        routes: [
          GoRoute(
            path: 'todo/:id',
            builder: (_, state) => TodoDetailWebViewScreen(
              todo: state.extra as Todo,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/new',
        pageBuilder: (ctx, s) => const MaterialPage(
          fullscreenDialog: true,
          child: TodoFormScreen(),
        ),
      ),
      GoRoute(
        path: '/edit',
        pageBuilder: (_, state) => MaterialPage(
          fullscreenDialog: true,
          child: TodoFormScreen(todo: state.extra as Todo),
        ),
      ),
    ],
  );
});
