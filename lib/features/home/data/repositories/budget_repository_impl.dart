import '../../domain/repositories/budget_repository.dart';
import '../datasources/budget_local_data_source.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  const BudgetRepositoryImpl(this._local);

  final BudgetLocalDataSource _local;

  @override
  double readBudget() => _local.readBudget();

  @override
  Future<void> saveBudget(double amount) => _local.saveBudget(amount);
}
