import 'package:flutter/foundation.dart';

/// Outcome of a single sync attempt.
enum SyncResult { success, noSession, alreadyRunning, offline, unauthorized }

/// What the home header badge shows at a glance.
enum SyncPhase { idle, syncing, synced, pending, offline, error }

@immutable
final class SyncSnapshot {
  const SyncSnapshot({
    this.phase = SyncPhase.idle,
    this.pendingCount = 0,
    this.lastSyncedAt,
    this.online = true,
  });

  final SyncPhase phase;
  final int pendingCount;
  final DateTime? lastSyncedAt;
  final bool online;

  SyncSnapshot copyWith({
    SyncPhase? phase,
    int? pendingCount,
    DateTime? lastSyncedAt,
    bool? online,
  }) {
    return SyncSnapshot(
      phase: phase ?? this.phase,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      online: online ?? this.online,
    );
  }
}

/// Shared sync state: the coordinator writes to it, the badge reads from it.
final class SyncStatusStore {
  final ValueNotifier<SyncSnapshot> value = ValueNotifier(const SyncSnapshot());

  SyncSnapshot get snapshot => value.value;

  /// Tracks connectivity separately from the sync result so the badge can show
  /// "Offline" the moment the network drops, before any request fails.
  void setOnline(bool online) {
    final current = value.value;
    value.value = current.copyWith(
      online: online,
      phase: !online
          ? SyncPhase.offline
          : (current.phase == SyncPhase.offline
                ? SyncPhase.idle
                : current.phase),
    );
  }

  /// Mirrors the outbox size so pending edits are visible even before a sync.
  void setPending(int count) {
    final current = value.value;
    if (current.pendingCount == count) return;
    value.value = current.copyWith(
      pendingCount: count,
      phase: current.phase == SyncPhase.syncing || !current.online
          ? current.phase
          : (count > 0 ? SyncPhase.pending : SyncPhase.synced),
    );
  }

  void begin() => value.value = value.value.copyWith(phase: SyncPhase.syncing);

  void finish(SyncResult result, {required int pendingCount}) {
    final current = value.value;
    value.value = current.copyWith(
      pendingCount: pendingCount,
      lastSyncedAt: result == SyncResult.success
          ? DateTime.now()
          : current.lastSyncedAt,
      phase: _phaseFor(result, pendingCount, current.online),
    );
  }

  SyncPhase _phaseFor(SyncResult result, int pending, bool online) {
    if (!online || result == SyncResult.offline) return SyncPhase.offline;
    return switch (result) {
      SyncResult.success => pending > 0 ? SyncPhase.pending : SyncPhase.synced,
      // Covered by the guard above; listed for exhaustiveness.
      SyncResult.offline => SyncPhase.offline,
      SyncResult.noSession => SyncPhase.idle,
      SyncResult.alreadyRunning => SyncPhase.syncing,
      SyncResult.unauthorized => SyncPhase.error,
    };
  }

  void dispose() => value.dispose();
}
