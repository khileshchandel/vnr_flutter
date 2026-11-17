import 'package:flutter_test/flutter_test.dart';

import 'package:e_track/app/router/auth_redirect.dart';
import 'package:e_track/core/constants/app_routes.dart';
import 'package:e_track/features/auth/presentation/bloc/auth_state.dart';

void main() {
  test('unauthenticated users are sent to login', () {
    expect(
      authRedirect(AuthStatus.unauthenticated, AppRoutes.splash),
      AppRoutes.login,
    );
    expect(
      authRedirect(AuthStatus.unauthenticated, AppRoutes.home),
      AppRoutes.login,
    );
    expect(authRedirect(AuthStatus.unauthenticated, AppRoutes.login), isNull);
  });

  test('successful sign-in moves splash and login to home', () {
    expect(
      authRedirect(AuthStatus.authenticated, AppRoutes.splash),
      AppRoutes.home,
    );
    expect(
      authRedirect(AuthStatus.authenticated, AppRoutes.login),
      AppRoutes.home,
    );
  });

  test('authenticated users can stay on other pages', () {
    expect(authRedirect(AuthStatus.authenticated, AppRoutes.home), isNull);
    expect(authRedirect(AuthStatus.authenticated, AppRoutes.tasks), isNull);
  });

  test('no redirect while auth status is pending', () {
    expect(authRedirect(AuthStatus.unknown, AppRoutes.splash), isNull);
    expect(authRedirect(AuthStatus.authenticating, AppRoutes.login), isNull);
  });
}
