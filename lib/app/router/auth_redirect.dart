import '../../core/constants/app_routes.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';

/// Pure auth routing rule. Returns the location to redirect to, or null to keep
/// the current one. Keeping this separate makes navigation easy to test.
String? authRedirect(AuthStatus status, String location) {
  final isSplash = location == AppRoutes.splash;
  final isLogin = location == AppRoutes.login;

  return switch (status) {
    AuthStatus.unknown || AuthStatus.authenticating => null,
    AuthStatus.authenticated => isSplash || isLogin ? AppRoutes.home : null,
    AuthStatus.unauthenticated => isLogin ? null : AppRoutes.login,
  };
}
