import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:e_track/app/navigation/scaffold_with_nav_bar.dart';

Widget _page(String label) => Scaffold(body: Center(child: Text(label)));

GoRouter _routerWithTabs() => GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => ScaffoldWithNavBar(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, _) => _page('home page'),
              routes: [
                GoRoute(
                  path: 'expenses',
                  builder: (_, _) => _page('expenses page'),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/search', builder: (_, _) => _page('search page')),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/profile', builder: (_, _) => _page('profile page')),
          ],
        ),
      ],
    ),
  ],
);

void main() {
  testWidgets('bottom navigation switches between the three tabs', (
    tester,
  ) async {
    final router = _routerWithTabs();
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('home page'), findsOneWidget);

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.text('search page'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('profile page'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('home page'), findsOneWidget);
  });

  testWidgets('expenses route stays inside the home branch', (tester) async {
    final router = _routerWithTabs();
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    router.go('/home/expenses');
    await tester.pumpAndSettle();

    expect(router.state.matchedLocation, '/home/expenses');
    expect(find.text('expenses page'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });
}
