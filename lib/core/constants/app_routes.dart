abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String search = '/search';
  static const String profile = '/profile';

  /// Nested under /home so the bottom navigation stays visible.
  static const String expenses = '/home/expenses';
  static const String tasks = '/home/tasks';
}
