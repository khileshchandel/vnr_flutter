import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/expenses/presentation/pages/expenses_page.dart';
import '../../features/tasks/presentation/pages/tasks_page.dart';
import 'auth_redirect.dart';

/// go_router refreshes whenever this changes, so auth state drives navigation
/// without any page having to listen for it.
final ValueNotifier<AuthStatus> authStatusNotifier = ValueNotifier(
  AuthStatus.unknown,
);

/// Single source of truth for navigation.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  refreshListenable: authStatusNotifier,
  redirect: (_, state) =>
      authRedirect(authStatusNotifier.value, state.matchedLocation),
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      builder: (_, _) => const SplashPage(),
    ),
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (_, _) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (_, _) => const ExpensesPage(),
    ),
    GoRoute(
      path: AppRoutes.expenses,
      name: 'expenses',
      builder: (_, _) => const ExpensesPage(),
    ),
    GoRoute(
      path: AppRoutes.tasks,
      name: 'tasks',
      builder: (_, _) => const TasksPage(),
    ),
  ],
  errorBuilder: (_, state) =>
      SplashPage(message: 'Route not found: ${state.uri}'),
);
