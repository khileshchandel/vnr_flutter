import '../entities/task_item.dart';

/// Domain-facing access to tasks. The local-first implementation lives in the
/// data layer so presentation code never depends on Hive.
abstract interface class TaskRepository {
  List<TaskItem> getTasks();

  Future<void> cacheTask(TaskItem task);
}
