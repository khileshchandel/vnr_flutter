sealed class DashboardEvent {
  const DashboardEvent();
}

final class DashboardStarted extends DashboardEvent {
  const DashboardStarted();
}

final class BudgetUpdated extends DashboardEvent {
  const BudgetUpdated(this.amount);

  final double amount;
}
