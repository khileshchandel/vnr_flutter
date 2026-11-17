import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_track/core/sync/sync_coordinator.dart';
import 'package:e_track/core/sync/sync_status.dart';
import 'package:e_track/features/expenses/domain/entities/expense.dart';
import 'package:e_track/features/expenses/domain/repositories/expense_repository.dart';
import 'package:e_track/features/home/domain/repositories/budget_repository.dart';
import 'package:e_track/features/home/presentation/bloc/dashboard_bloc.dart';
import 'package:e_track/features/home/presentation/bloc/dashboard_event.dart';
import 'package:e_track/features/home/presentation/pages/home_page.dart';
import 'package:e_track/features/tasks/domain/entities/task_item.dart';
import 'package:e_track/features/tasks/domain/repositories/task_repository.dart';

class _FakeSyncService implements SyncService {
  @override
  Future<SyncResult> run() async => SyncResult.success;
}

void main() {
  testWidgets('dashboard shows summary, breakdown and recent tabs', (
    tester,
  ) async {
    final bloc = DashboardBloc(
      expenses: _StaticExpenses([
        Expense(
          id: 'e1',
          title: 'Coffee',
          amount: 250,
          category: 'Food',
          date: DateTime.utc(2026, 11, 17),
        ),
      ]),
      tasks: _StaticTasks([const TaskItem(id: 't1', title: 'Pay bills')]),
      budget: _StaticBudget(50000),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MultiRepositoryProvider(
          providers: [
            RepositoryProvider<SyncService>.value(value: _FakeSyncService()),
            RepositoryProvider<SyncStatusStore>.value(value: SyncStatusStore()),
          ],
          child: BlocProvider<DashboardBloc>(
            create: (_) => bloc..add(const DashboardStarted()),
            child: const HomePage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Remaining budget'), findsOneWidget);
    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('Spent'), findsOneWidget);
    // Remaining budget animates to ₹49,750; the Budget stat shows ₹50,000.
    expect(find.text('₹49,750'), findsOneWidget);
    expect(find.text('₹50,000'), findsOneWidget);
    expect(find.text('Spend by category'), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.byTooltip('Refresh'), findsNothing);
    expect(find.byTooltip('Sign out'), findsNothing);

    expect(find.text('Recent activity'), findsOneWidget);
    expect(find.text('Tasks (1)'), findsOneWidget);
    expect(find.text('Pay bills'), findsOneWidget);
    expect(find.byTooltip('Add task'), findsOneWidget);
    expect(find.text('See all'), findsOneWidget);
    expect(find.text('Expenses (1)'), findsOneWidget);

    await tester.ensureVisible(find.text('Expenses (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Expenses (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.byTooltip('Add expense'), findsOneWidget);
    expect(find.text('See all'), findsOneWidget);
  });
}

class _StaticExpenses implements ExpenseRepository {
  const _StaticExpenses(this.items);

  final List<Expense> items;

  @override
  Stream<void> get changes => const Stream<void>.empty();

  @override
  List<Expense> getExpenses() => items;

  @override
  Expense? findById(String id) => null;

  @override
  Future<void> cacheExpense(Expense expense) async {}

  @override
  Future<void> deleteExpense(String id) async {}

  @override
  Future<void> applyRemoteExpense(Expense expense) async {}

  @override
  Future<void> markSynced(String id, {DateTime? updatedAt}) async {}
}

class _StaticTasks implements TaskRepository {
  const _StaticTasks(this.items);

  final List<TaskItem> items;

  @override
  Stream<void> get changes => const Stream<void>.empty();

  @override
  List<TaskItem> getTasks() => items;

  @override
  TaskItem? findById(String id) => null;

  @override
  Future<void> cacheTask(TaskItem task) async {}

  @override
  Future<void> deleteTask(String id) async {}

  @override
  Future<void> applyRemoteTask(TaskItem task) async {}

  @override
  Future<void> markSynced(String id, {DateTime? updatedAt}) async {}
}

class _StaticBudget implements BudgetRepository {
  const _StaticBudget(this.value);

  final double value;

  @override
  double readBudget() => value;

  @override
  Future<void> saveBudget(double amount) async {}
}
