import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/task_item.dart';

abstract interface class TaskRemoteDataSource {
  Future<List<TaskItem>> fetch({
    required String token,
    DateTime? updatedAfter,
    int limit = 200,
  });

  Future<TaskItem> upsert({required String token, required TaskItem task});

  Future<bool> delete({required String token, required String id});
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  const TaskRemoteDataSourceImpl(this._api);

  final ApiClient _api;

  Map<String, dynamic> _fromRemote(Map<String, dynamic> json) {
    // The API calls this field `description`; the domain calls it `note`.
    final mapped = Map<String, dynamic>.from(json);
    mapped['note'] = json['description'] ?? json['note'];
    return mapped;
  }

  @override
  Future<List<TaskItem>> fetch({
    required String token,
    DateTime? updatedAfter,
    int limit = 200,
  }) async {
    final response = await _api.getJson(
      '/tasks',
      queryParameters: {
        'limit': '$limit',
        if (updatedAfter != null)
          'updatedAfter': updatedAfter.toIso8601String(),
      },
      token: token,
    );
    final items = response['items'];
    if (items is! List<dynamic>) {
      throw const ServerFailure('Unexpected tasks response.');
    }
    return items
        .whereType<Map<String, dynamic>>()
        .map((json) => TaskItem.fromJson(_fromRemote(json)))
        .toList();
  }

  @override
  Future<TaskItem> upsert({
    required String token,
    required TaskItem task,
  }) async {
    final response = await _api.putJson(
      '/tasks/${task.id}',
      body: {
        'title': task.title,
        'category': task.category.wireValue,
        'description': task.note,
        'dueDate': task.dueDate?.toIso8601String(),
        'isCompleted': task.isCompleted,
      },
      token: token,
    );
    return TaskItem.fromJson(_fromRemote(response));
  }

  @override
  Future<bool> delete({required String token, required String id}) {
    return _api.deleteJson('/tasks/$id', token: token, missingIsSuccess: true);
  }
}
