import 'sync_status.dart';

/// Short user-facing text for a manual sync attempt.
String syncMessage(SyncResult result) => switch (result) {
  SyncResult.success => 'Everything is up to date.',
  SyncResult.noSession => 'Sign in to sync your data.',
  SyncResult.alreadyRunning => 'A sync is already in progress.',
  SyncResult.offline => 'Offline. Your changes are saved and will sync later.',
  SyncResult.unauthorized => 'Session expired. Please sign in again.',
};

/// Tooltip text for the home header sync badge.
String syncBadgeLabel(SyncSnapshot snapshot) => switch (snapshot.phase) {
  SyncPhase.syncing => 'Syncing…',
  SyncPhase.synced => 'All changes synced',
  SyncPhase.pending =>
    '${snapshot.pendingCount} change${snapshot.pendingCount == 1 ? '' : 's'} waiting to sync',
  SyncPhase.offline => 'Offline — changes will sync when connected',
  SyncPhase.error => 'Sync needs attention — please sign in again',
  SyncPhase.idle => 'Not synced yet — tap to sync',
};
