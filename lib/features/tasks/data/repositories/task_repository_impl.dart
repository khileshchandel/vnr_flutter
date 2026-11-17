import 'dart:async';

import '../../domain/entities/task_item.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_data_source.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._local);

  final TaskLocalDataSource _local;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

  @override
  List<TaskItem> getTasks() => _local.getTasks();

  @override
  Future<void> cacheTask(TaskItem task) async {
    await _local.cacheTask(task);
    _changes.add(null);
  }
}
