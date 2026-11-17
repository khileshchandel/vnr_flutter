import 'package:hive/hive.dart';

import '../../domain/entities/expense.dart';

/// Hive-backed local store. Expenses are written here first; the sync service
/// will later drain `pendingSyncBox` when connectivity is available.
abstract interface class ExpenseLocalDataSource {
  List<Expense> getExpenses();

  Future<void> cacheExpense(Expense expense);
}

class ExpenseLocalDataSourceImpl implements ExpenseLocalDataSource {
  const ExpenseLocalDataSourceImpl(this._box);

  final Box<Map<String, dynamic>> _box;

  @override
  List<Expense> getExpenses() {
    final expenses = _box.values.map(Expense.fromJson).toList();
    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }

  @override
  Future<void> cacheExpense(Expense expense) =>
      _box.put(expense.id, expense.toJson());
}
