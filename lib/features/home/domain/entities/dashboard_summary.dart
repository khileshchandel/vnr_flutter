import '../../../expenses/domain/entities/expense.dart';
import '../../../tasks/domain/entities/task_item.dart';

/// Default monthly budget used until the user sets their own.
const double defaultBudget = 50000;

class CategorySpend {
  const CategorySpend({
    required this.category,
    required this.amount,
    required this.share,
  });

  final String category;
  final double amount;

  /// Fraction of total spend, between 0 and 1.
  final double share;
}

/// Everything the dashboard needs, computed from local data.
class DashboardSummary {
  const DashboardSummary({
    required this.budget,
    required this.totalSpent,
    required this.categorySpend,
    required this.recentExpenses,
    required this.recentTasks,
  });

  final double budget;
  final double totalSpent;
  final List<CategorySpend> categorySpend;
  final List<Expense> recentExpenses;
  final List<TaskItem> recentTasks;

  double get remaining => budget - totalSpent;

  /// Fraction of the budget used, capped at 1 for the progress bar.
  double get usedFraction =>
      budget <= 0 ? 0 : (totalSpent / budget).clamp(0.0, 1.0);

  double get usedPercent => budget <= 0 ? 0 : (totalSpent / budget) * 100;
}
