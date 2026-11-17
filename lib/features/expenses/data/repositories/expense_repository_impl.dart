import 'dart:async';

import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_local_data_source.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  ExpenseRepositoryImpl(this._local);

  final ExpenseLocalDataSource _local;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

  @override
  List<Expense> getExpenses() => _local.getExpenses();

  @override
  Future<void> cacheExpense(Expense expense) async {
    await _local.cacheExpense(expense);
    _changes.add(null);
  }
}
