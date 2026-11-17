import '../../domain/entities/task_item.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_data_source.dart';

class TaskRepositoryImpl implements TaskRepository {
  const TaskRepositoryImpl(this._local);

  final TaskLocalDataSource _local;

  @override
  List<TaskItem> getTasks() => _local.getTasks();

  @override
  Future<void> cacheTask(TaskItem task) => _local.cacheTask(task);
}
