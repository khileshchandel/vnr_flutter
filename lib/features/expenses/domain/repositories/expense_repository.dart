import '../entities/expense.dart';

/// Domain-facing access to expenses. The local-first implementation lives in
/// the data layer so presentation code never depends on Hive.
abstract interface class ExpenseRepository {
  List<Expense> getExpenses();

  Expense? findById(String id);

  /// Writes locally, queues an upsert in the outbox and emits a change.
  Future<void> cacheExpense(Expense expense);

  /// Removes locally, queues a delete in the outbox and emits a change.
  Future<void> deleteExpense(String id);

  /// Applies a server record without queuing another upload.
  Future<void> applyRemoteExpense(Expense expense);

  /// Marks a local record as uploaded after the server acknowledged it.
  Future<void> markSynced(String id, {DateTime? updatedAt});

  /// Emits after a local write so listeners such as the dashboard can refresh.
  Stream<void> get changes;
}
