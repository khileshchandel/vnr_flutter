import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:e_track/core/network/connectivity_service.dart';
import 'package:e_track/core/sync/auto_sync_manager.dart';
import 'package:e_track/core/sync/sync_coordinator.dart';
import 'package:e_track/core/sync/sync_status.dart';

class _FakeConnectivity implements ConnectivityService {
  final _controller = StreamController<bool>.broadcast();
  bool _online = false;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  @override
  Future<bool> isOnline() async => _online;

  void emit(bool online) {
    _online = online;
    _controller.add(online);
  }
}

class _CountingSync implements SyncService {
  int calls = 0;

  @override
  Future<SyncResult> run() async {
    calls++;
    return SyncResult.success;
  }
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  test('reconnect triggers a sync while going offline does not', () async {
    final connectivity = _FakeConnectivity();
    final sync = _CountingSync();
    final status = SyncStatusStore();
    final manager = AutoSyncManager(connectivity, sync, status);

    await manager.start();
    expect(sync.calls, 0); // starts offline
    expect(status.snapshot.online, isFalse);

    connectivity.emit(true);
    await _flush();
    expect(sync.calls, 1);
    expect(status.snapshot.online, isTrue);

    connectivity.emit(false);
    await _flush();
    expect(sync.calls, 1);
    expect(status.snapshot.phase, SyncPhase.offline);

    connectivity.emit(true);
    await _flush();
    expect(sync.calls, 2);

    await manager.stop();
    status.dispose();
  });

  test('status store tracks pending work and sync outcomes', () {
    final status = SyncStatusStore();

    status.setPending(2);
    expect(status.snapshot.phase, SyncPhase.pending);
    expect(status.snapshot.pendingCount, 2);

    status.begin();
    expect(status.snapshot.phase, SyncPhase.syncing);

    status.finish(SyncResult.success, pendingCount: 0);
    expect(status.snapshot.phase, SyncPhase.synced);
    expect(status.snapshot.lastSyncedAt, isNotNull);

    status.setOnline(false);
    expect(status.snapshot.phase, SyncPhase.offline);

    status.dispose();
  });
}
