import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/expenses/presentation/pages/expenses_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/tasks/presentation/pages/tasks_page.dart';
import '../navigation/scaffold_with_nav_bar.dart';
import 'auth_redirect.dart';

/// go_router refreshes whenever this changes, so auth state drives navigation
/// without any page having to listen for it.
final ValueNotifier<AuthStatus> authStatusNotifier = ValueNotifier(
  AuthStatus.unknown,
);

/// Single source of truth for navigation. The indexed shell keeps Home, Search
/// and Profile alive in their own navigators while auth routes stay outside it.
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
    StatefulShellRoute.indexedStack(
      builder: (_, _, navigationShell) =>
          ScaffoldWithNavBar(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              name: 'home',
              builder: (_, _) => const HomePage(),
              routes: [
                GoRoute(
                  path: 'expenses',
                  name: 'expenses',
                  builder: (_, _) => const ExpensesPage(),
                ),
                GoRoute(
                  path: 'tasks',
                  name: 'tasks',
                  builder: (_, _) => const TasksPage(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.search,
              name: 'search',
              builder: (_, _) => const SearchPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              name: 'profile',
              builder: (_, _) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),
  ],
  errorBuilder: (_, state) =>
      SplashPage(message: 'Route not found: ${state.uri}'),
);
