/// App-wide constants. Keep environment-specific values overridable at build
/// time with `--dart-define` instead of hard-coding them in features.
abstract final class AppConstants {
  static const String appName = 'E Track';

  /// Android emulator uses 10.0.2.2 to reach the host machine.
  /// Override with: --dart-define=ETRACK_API_BASE_URL=http://your-ip:8000/api
  static const String apiBaseUrl = String.fromEnvironment(
    'ETRACK_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  // flutter_secure_storage keys
  static const String accessTokenKey = 'etrack_access_token';
  static const String refreshTokenKey = 'etrack_refresh_token';

  // Hive box names
  static const String expensesBox = 'etrack_expenses';
  static const String pendingSyncBox = 'etrack_pending_sync';
  static const String settingsBox = 'etrack_settings';
}
