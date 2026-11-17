import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/expense.dart';

abstract interface class ExpenseRemoteDataSource {
  Future<List<Expense>> fetch({
    required String token,
    DateTime? updatedAfter,
    int limit = 200,
  });

  Future<Expense> upsert({required String token, required Expense expense});

  Future<bool> delete({required String token, required String id});
}

class ExpenseRemoteDataSourceImpl implements ExpenseRemoteDataSource {
  const ExpenseRemoteDataSourceImpl(this._api);

  final ApiClient _api;

  @override
  Future<List<Expense>> fetch({
    required String token,
    DateTime? updatedAfter,
    int limit = 200,
  }) async {
    final response = await _api.getJson(
      '/expenses',
      queryParameters: {
        'limit': '$limit',
        if (updatedAfter != null)
          'updatedAfter': updatedAfter.toIso8601String(),
      },
      token: token,
    );
    final items = response['items'];
    if (items is! List<dynamic>) {
      throw const ServerFailure('Unexpected expenses response.');
    }
    return items
        .whereType<Map<String, dynamic>>()
        .map(Expense.fromJson)
        .toList();
  }

  @override
  Future<Expense> upsert({
    required String token,
    required Expense expense,
  }) async {
    final response = await _api.putJson(
      '/expenses/${expense.id}',
      body: {
        'title': expense.title,
        'amount': expense.amount,
        'category': expense.category,
        'date': expense.date.toIso8601String(),
        'note': expense.note,
      },
      token: token,
    );
    return Expense.fromJson(response);
  }

  @override
  Future<bool> delete({required String token, required String id}) {
    return _api.deleteJson(
      '/expenses/$id',
      token: token,
      missingIsSuccess: true,
    );
  }
}
