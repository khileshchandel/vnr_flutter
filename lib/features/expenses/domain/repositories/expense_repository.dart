import '../entities/expense.dart';

/// Domain-facing access to expenses. The local-first implementation lives in
/// the data layer so presentation code never depends on Hive.
abstract interface class ExpenseRepository {
  List<Expense> getExpenses();

  Future<void> cacheExpense(Expense expense);

  /// Emits after a local write so listeners such as the dashboard can refresh.
  Stream<void> get changes;
}
