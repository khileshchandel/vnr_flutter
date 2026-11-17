/// App-wide constants. Keep environment-specific values overridable at build
/// time with `--dart-define` instead of hard-coding them in features.
abstract final class AppConstants {
  static const String appName = 'E Track';

  /// Deployed E Track API host. ApiClient appends the `/api` route prefix.
  /// Override for local testing with:
  /// --dart-define=ETRACK_API_BASE_URL=http://10.0.2.2:8000
  static const String apiBaseUrl = String.fromEnvironment(
    'ETRACK_API_BASE_URL',
    defaultValue: 'https://vnr-deno.itssagarbro.deno.net/',
  );

  // flutter_secure_storage keys
  static const String accessTokenKey = 'etrack_access_token';
  static const String refreshTokenKey = 'etrack_refresh_token';

  // Hive box names
  static const String expensesBox = 'etrack_expenses';
  static const String tasksBox = 'etrack_tasks';
  static const String pendingSyncBox = 'etrack_pending_sync';
  static const String settingsBox = 'etrack_settings';
}
