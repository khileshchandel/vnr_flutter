import 'sync_coordinator.dart';

/// Short user-facing text for a manual sync attempt.
String syncMessage(SyncResult result) => switch (result) {
  SyncResult.success => 'Everything is up to date.',
  SyncResult.noSession => 'Sign in to sync your data.',
  SyncResult.alreadyRunning => 'A sync is already in progress.',
  SyncResult.offline => 'Offline. Your changes are saved and will sync later.',
  SyncResult.unauthorized => 'Session expired. Please sign in again.',
};
