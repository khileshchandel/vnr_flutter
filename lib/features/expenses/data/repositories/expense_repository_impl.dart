import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_local_data_source.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  const ExpenseRepositoryImpl(this._local);

  final ExpenseLocalDataSource _local;

  @override
  List<Expense> getExpenses() => _local.getExpenses();

  @override
  Future<void> cacheExpense(Expense expense) => _local.cacheExpense(expense);
}
