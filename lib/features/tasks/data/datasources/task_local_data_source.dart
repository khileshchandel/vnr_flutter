import 'package:hive/hive.dart';

import '../../domain/entities/task_item.dart';

/// Hive-backed local store for tasks. Writes happen here first; a future sync
/// service will drain the shared outbox when the API is available.
abstract interface class TaskLocalDataSource {
  List<TaskItem> getTasks();

  Future<void> cacheTask(TaskItem task);
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  const TaskLocalDataSourceImpl(this._box);

  final Box<Map<String, dynamic>> _box;

  @override
  List<TaskItem> getTasks() {
    final tasks = _box.values.map(TaskItem.fromJson).toList();

    tasks.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      if (a.dueDate == null && b.dueDate == null) {
        return a.title.compareTo(b.title);
      }
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });

    return tasks;
  }

  @override
  Future<void> cacheTask(TaskItem task) => _box.put(task.id, task.toJson());
}
