import 'package:go_router/go_router.dart';
import 'features/todo/pages/todo_list_page.dart';
import 'features/todo/pages/todo_detail_page.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const TodoListPage(),
    ),
    GoRoute(
      path: '/todos/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return TodoDetailPage(todoId: id);
      },
    ),
  ],
);
