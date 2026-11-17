import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/expenses/presentation/pages/expenses_page.dart';

/// Single source of truth for navigation.
///
/// Auth-aware redirects will be added here once the API login flow is wired.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
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
  ],
  errorBuilder: (_, state) =>
      SplashPage(message: 'Route not found: ${state.uri}'),
);
