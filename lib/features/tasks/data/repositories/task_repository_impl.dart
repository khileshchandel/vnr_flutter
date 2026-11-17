import 'dart:async';

import '../../../../core/sync/sync_outbox.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_data_source.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._local, this._outbox);

  final TaskLocalDataSource _local;
  final SyncOutbox _outbox;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

  @override
  List<TaskItem> getTasks() => _local.getTasks();

  @override
  TaskItem? findById(String id) => _local.find(id);

  @override
  Future<void> cacheTask(TaskItem task) async {
    await _local.put(task.copyWith(isSynced: false, clearDeletedAt: true));
    await _outbox.enqueue(
      kind: SyncOperationKind.upsertTask,
      recordId: task.id,
    );
    _changes.add(null);
  }

  @override
  Future<void> deleteTask(String id) async {
    await _local.remove(id);
    await _outbox.enqueue(kind: SyncOperationKind.deleteTask, recordId: id);
    _changes.add(null);
  }

  @override
  Future<void> applyRemoteTask(TaskItem task) async {
    if (_outbox.hasPending(task.id)) return;
    final local = _local.find(task.id);
    if (local != null && !local.isSynced) return;

    if (task.deletedAt != null) {
      await _local.remove(task.id);
    } else {
      await _local.put(task.copyWith(isSynced: true));
    }
    _changes.add(null);
  }

  @override
  Future<void> markSynced(String id, {DateTime? updatedAt}) async {
    final local = _local.find(id);
    if (local == null) return;
    await _local.put(
      local.copyWith(
        isSynced: true,
        updatedAt: updatedAt,
        clearDeletedAt: true,
      ),
    );
    _changes.add(null);
  }
}
