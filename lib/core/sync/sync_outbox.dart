import 'dart:async';

/// One queued mutation waiting to reach the API.
enum SyncOperationKind { upsertExpense, deleteExpense, upsertTask, deleteTask }

final class PendingSyncOperation {
  const PendingSyncOperation({
    required this.id,
    required this.kind,
    required this.recordId,
    required this.ownerId,
    required this.createdAt,
  });

  final String id;
  final SyncOperationKind kind;
  final String recordId;
  final String ownerId;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'recordId': recordId,
    'ownerId': ownerId,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PendingSyncOperation.fromJson(Map<String, dynamic> json) {
    return PendingSyncOperation(
      id: json['id'] as String,
      kind: SyncOperationKind.values.byName(json['kind'] as String),
      recordId: json['recordId'] as String,
      ownerId: json['ownerId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Outbox for local writes. Only the active account's operations are drained.
abstract interface class SyncOutbox {
  Stream<void> get changes;

  List<PendingSyncOperation> readAll();

  bool hasPending(String recordId);

  /// Replaces any earlier operation for the same record, so create → edit →
  /// delete collapses into the final intent instead of replaying history.
  Future<void> enqueue({
    required SyncOperationKind kind,
    required String recordId,
  });

  Future<void> remove(String operationId);
}
