import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:e_track/app/router/auth_redirect.dart';
import 'package:e_track/core/constants/app_routes.dart';
import 'package:e_track/features/auth/presentation/bloc/auth_state.dart';

Widget _page(String label) => Scaffold(body: Center(child: Text(label)));

void main() {
  testWidgets('auth status changes drive router redirects', (tester) async {
    final notifier = ValueNotifier<AuthStatus>(AuthStatus.unknown);
    final router = GoRouter(
      initialLocation: AppRoutes.splash,
      refreshListenable: notifier,
      redirect: (_, state) =>
          authRedirect(notifier.value, state.matchedLocation),
      routes: [
        GoRoute(path: AppRoutes.splash, builder: (_, _) => _page('splash')),
        GoRoute(path: AppRoutes.login, builder: (_, _) => _page('login')),
        GoRoute(path: AppRoutes.home, builder: (_, _) => _page('home')),
      ],
    );
    addTearDown(() {
      router.dispose();
      notifier.dispose();
    });

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(router.state.matchedLocation, AppRoutes.splash);

    notifier.value = AuthStatus.unauthenticated;
    await tester.pumpAndSettle();
    expect(router.state.matchedLocation, AppRoutes.login);

    notifier.value = AuthStatus.authenticated;
    await tester.pumpAndSettle();
    expect(router.state.matchedLocation, AppRoutes.home);

    notifier.value = AuthStatus.unauthenticated;
    await tester.pumpAndSettle();
    expect(router.state.matchedLocation, AppRoutes.login);
  });
}
