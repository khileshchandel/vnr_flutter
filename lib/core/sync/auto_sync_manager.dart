import 'dart:async';

import '../network/connectivity_service.dart';
import 'sync_coordinator.dart';
import 'sync_status.dart';

/// Runs a sync whenever the device (re)connects and keeps the badge's online
/// flag current. Fully injectable so tests can drive reconnects by hand.
final class AutoSyncManager {
  AutoSyncManager(this._connectivity, this._sync, this._status);

  final ConnectivityService _connectivity;
  final SyncService _sync;
  final SyncStatusStore _status;

  StreamSubscription<bool>? _subscription;
  bool? _wasOnline;

  Future<void> start() async {
    if (_subscription != null) return;
    _subscription = _connectivity.onConnectivityChanged.listen(_onChanged);

    // The stream only reports changes, so seed it with the current state.
    final online = await _connectivity.isOnline();
    _onChanged(online, initial: true);
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _wasOnline = null;
  }

  void _onChanged(bool online, {bool initial = false}) {
    final wasOnline = _wasOnline;
    _wasOnline = online;
    _status.setOnline(online);

    // Reconnect (or first online reading) is the trigger. Going offline never
    // calls the API — local writes simply stay in the outbox.
    if (online && (initial || wasOnline == false)) {
      unawaited(_sync.run());
    }
  }
}
