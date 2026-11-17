import '../entities/task_item.dart';

/// Domain-facing access to tasks. The local-first implementation lives in the
/// data layer so presentation code never depends on Hive.
abstract interface class TaskRepository {
  List<TaskItem> getTasks();

  TaskItem? findById(String id);

  /// Writes locally, queues an upsert in the outbox and emits a change.
  Future<void> cacheTask(TaskItem task);

  /// Removes locally, queues a delete in the outbox and emits a change.
  Future<void> deleteTask(String id);

  /// Applies a server record without queuing another upload.
  Future<void> applyRemoteTask(TaskItem task);

  /// Marks a local record as uploaded after the server acknowledged it.
  Future<void> markSynced(String id, {DateTime? updatedAt});

  /// Emits after a local write so listeners such as the dashboard can refresh.
  Stream<void> get changes;
}
