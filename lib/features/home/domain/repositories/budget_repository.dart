/// User-editable total budget, persisted outside the feature's presentation
/// layer so the dashboard bloc stays independent of Hive.
abstract interface class BudgetRepository {
  double readBudget();

  Future<void> saveBudget(double amount);
}
