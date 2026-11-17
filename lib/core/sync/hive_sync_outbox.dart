import 'dart:async';

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../auth/user_id_provider.dart';
import 'sync_outbox.dart';

final class HiveSyncOutbox implements SyncOutbox {
  HiveSyncOutbox(this._box, this._userId);

  final Box<Map<String, dynamic>> _box;
  final UserIdProvider _userId;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  String get _owner => _userId.userId ?? 'local';

  @override
  Stream<void> get changes => _changes.stream;

  @override
  List<PendingSyncOperation> readAll() {
    final operations =
        _box.values
            .where((json) => json['ownerId'] == _owner)
            .map(PendingSyncOperation.fromJson)
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return operations;
  }

  @override
  bool hasPending(String recordId) =>
      readAll().any((operation) => operation.recordId == recordId);

  @override
  Future<void> enqueue({
    required SyncOperationKind kind,
    required String recordId,
  }) async {
    final existing = readAll().where(
      (operation) => operation.recordId == recordId && operation.kind == kind,
    );
    for (final operation in existing.toList()) {
      await _box.delete(operation.id);
    }

    final operation = PendingSyncOperation(
      id: const Uuid().v4(),
      kind: kind,
      recordId: recordId,
      ownerId: _owner,
      createdAt: DateTime.now(),
    );
    await _box.put(operation.id, operation.toJson());
    _changes.add(null);
  }

  @override
  Future<void> remove(String operationId) async {
    await _box.delete(operationId);
    _changes.add(null);
  }
}
