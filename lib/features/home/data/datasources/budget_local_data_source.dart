import 'package:hive/hive.dart';

import '../../domain/entities/dashboard_summary.dart';

/// Stores the user's editable total budget in Hive's settings box.
abstract interface class BudgetLocalDataSource {
  double readBudget();

  Future<void> saveBudget(double amount);
}

class BudgetLocalDataSourceImpl implements BudgetLocalDataSource {
  const BudgetLocalDataSourceImpl(this._box);

  static const String _key = 'total_budget';

  final Box<String> _box;

  @override
  double readBudget() => double.tryParse(_box.get(_key) ?? '') ?? defaultBudget;

  @override
  Future<void> saveBudget(double amount) =>
      _box.put(_key, amount.toStringAsFixed(2));
}
