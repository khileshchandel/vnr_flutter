import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:e_track/features/expenses/domain/entities/expense.dart';
import 'package:e_track/features/expenses/domain/repositories/expense_repository.dart';
import 'package:e_track/features/home/domain/entities/dashboard_summary.dart';
import 'package:e_track/features/home/domain/repositories/budget_repository.dart';
import 'package:e_track/features/home/presentation/bloc/dashboard_bloc.dart';
import 'package:e_track/features/home/presentation/bloc/dashboard_event.dart';
import 'package:e_track/features/home/presentation/bloc/dashboard_state.dart';
import 'package:e_track/features/tasks/domain/entities/task_item.dart';
import 'package:e_track/features/tasks/domain/repositories/task_repository.dart';

class _FakeExpenses implements ExpenseRepository {
  _FakeExpenses(this.items);

  final List<Expense> items;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

  @override
  List<Expense> getExpenses() => items;

  @override
  Future<void> cacheExpense(Expense expense) async {
    items.add(expense);
    _changes.add(null);
  }
}

class _FakeTasks implements TaskRepository {
  _FakeTasks(this.items);

  final List<TaskItem> items;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

  @override
  List<TaskItem> getTasks() => items;

  @override
  Future<void> cacheTask(TaskItem task) async {
    items.add(task);
    _changes.add(null);
  }
}

class _FakeBudget implements BudgetRepository {
  _FakeBudget(this.value);

  double value;

  @override
  double readBudget() => value;

  @override
  Future<void> saveBudget(double amount) async => value = amount;
}

Expense _expense(String id, String category, double amount) => Expense(
  id: id,
  title: id,
  amount: amount,
  category: category,
  date: DateTime.utc(2026, 11, int.parse(id)),
);

void main() {
  test(
    'dashboard computes totals, remaining balance and category shares',
    () async {
      final bloc = DashboardBloc(
        expenses: _FakeExpenses([
          _expense('1', 'Food', 1000),
          _expense('2', 'Travel', 500),
          _expense('3', 'Food', 500),
        ]),
        tasks: _FakeTasks([
          const TaskItem(id: 't1', title: 'Task one'),
          const TaskItem(id: 't2', title: 'Task two'),
        ]),
        budget: _FakeBudget(defaultBudget),
      );

      final ready = bloc.stream.firstWhere((state) => state.summary != null);
      bloc.add(const DashboardStarted());
      final summary = (await ready).summary!;

      expect(summary.budget, 50000);
      expect(summary.totalSpent, 2000);
      expect(summary.remaining, 48000);
      expect(summary.usedPercent, 4);
      expect(summary.recentExpenses, hasLength(3));
      expect(summary.recentTasks, hasLength(2));
      expect(summary.categorySpend.first.category, 'Food');
      expect(summary.categorySpend.first.amount, 1500);
      expect(summary.categorySpend.first.share, 0.75);
      expect(summary.categorySpend.last.share, 0.25);

      bloc.close();
    },
  );

  test('editing the budget persists it and refreshes the summary', () async {
    final budget = _FakeBudget(defaultBudget);
    final bloc = DashboardBloc(
      expenses: _FakeExpenses([]),
      tasks: _FakeTasks([]),
      budget: budget,
    );

    bloc.add(const DashboardStarted());
    final updated = bloc.stream.firstWhere(
      (state) => state.summary?.budget == 60000,
    );
    bloc.add(const BudgetUpdated(60000));

    final state = await updated;
    expect(state.status, DashboardStatus.ready);
    expect(state.summary!.remaining, 60000);
    expect(budget.value, 60000);

    bloc.close();
  });

  test('a new local expense refreshes the dashboard automatically', () async {
    final expenses = _FakeExpenses([]);
    final bloc = DashboardBloc(
      expenses: expenses,
      tasks: _FakeTasks([]),
      budget: _FakeBudget(defaultBudget),
    );
    final updated = bloc.stream.firstWhere(
      (state) => state.summary?.totalSpent == 500,
    );

    await expenses.cacheExpense(_expense('1', 'Food', 500));
    final state = await updated;

    expect(state.summary!.remaining, 49500);
    expect(state.summary!.recentExpenses, hasLength(1));

    bloc.close();
  });
}
