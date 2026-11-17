import 'package:hive/hive.dart';

import '../../../../core/auth/user_id_provider.dart';
import '../../domain/entities/task_item.dart';

/// Hive-backed local store. Reads are scoped to the signed-in account.
abstract interface class TaskLocalDataSource {
  List<TaskItem> getTasks();

  TaskItem? find(String id);

  Future<void> put(TaskItem task);

  Future<void> remove(String id);
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  TaskLocalDataSourceImpl(this._box, this._userId);

  final Box<Map<String, dynamic>> _box;
  final UserIdProvider _userId;

  String get _prefix => '${_userId.userId ?? 'local'}::';
  String _key(String id) => '$_prefix$id';

  @override
  List<TaskItem> getTasks() {
    final tasks = _box.keys
        .whereType<String>()
        .where((key) => key.startsWith(_prefix))
        .map((key) => TaskItem.fromJson(_box.get(key)!))
        .toList();

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
  TaskItem? find(String id) {
    final raw = _box.get(_key(id));
    return raw == null ? null : TaskItem.fromJson(raw);
  }

  @override
  Future<void> put(TaskItem task) => _box.put(_key(task.id), task.toJson());

  @override
  Future<void> remove(String id) => _box.delete(_key(id));
}
