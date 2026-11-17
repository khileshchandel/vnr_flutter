import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../tasks/domain/repositories/task_repository.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/budget_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

/// Builds the dashboard from local data. When the expense/task sync endpoints
/// land, this is the only place that needs to change.
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({
    required this._expenses,
    required this._tasks,
    required this._budget,
  }) : super(const DashboardState()) {
    on<DashboardStarted>((event, emit) => emit(_buildState()));
    on<BudgetUpdated>(_onBudgetUpdated);
  }

  final ExpenseRepository _expenses;
  final TaskRepository _tasks;
  final BudgetRepository _budget;

  Future<void> _onBudgetUpdated(
    BudgetUpdated event,
    Emitter<DashboardState> emit,
  ) async {
    await _budget.saveBudget(event.amount);
    emit(_buildState());
  }

  DashboardState _buildState() {
    final expenses = _expenses.getExpenses();
    final tasks = _tasks.getTasks();
    final totalSpent = expenses.fold<double>(
      0,
      (total, expense) => total + expense.amount,
    );

    final grouped = <String, double>{};
    for (final expense in expenses) {
      grouped[expense.category] =
          (grouped[expense.category] ?? 0) + expense.amount;
    }

    final categorySpend =
        grouped.entries
            .map(
              (entry) => CategorySpend(
                category: entry.key,
                amount: entry.value,
                share: totalSpent <= 0 ? 0 : entry.value / totalSpent,
              ),
            )
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    return DashboardState(
      status: DashboardStatus.ready,
      summary: DashboardSummary(
        budget: _budget.readBudget(),
        totalSpent: totalSpent,
        categorySpend: categorySpend,
        recentExpenses: expenses.take(5).toList(),
        recentTasks: tasks.take(5).toList(),
      ),
    );
  }
}
