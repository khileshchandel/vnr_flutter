import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_track/core/sync/sync_coordinator.dart';
import 'package:e_track/features/expenses/domain/entities/expense.dart';
import 'package:e_track/features/expenses/domain/repositories/expense_repository.dart';
import 'package:e_track/features/expenses/presentation/pages/expenses_page.dart';
import 'package:e_track/features/tasks/domain/entities/task_item.dart';
import 'package:e_track/features/tasks/domain/repositories/task_repository.dart';
import 'package:e_track/features/tasks/presentation/pages/tasks_page.dart';

class _FakeExpenseRepository implements ExpenseRepository {
  final List<Expense> expenses = [];
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

  @override
  List<Expense> getExpenses() => List.unmodifiable(expenses);

  @override
  Expense? findById(String id) {
    for (final expense in expenses) {
      if (expense.id == id) return expense;
    }
    return null;
  }

  @override
  Future<void> cacheExpense(Expense expense) async {
    expenses.removeWhere((item) => item.id == expense.id);
    expenses.add(expense);
    _changes.add(null);
  }

  @override
  Future<void> deleteExpense(String id) async {
    expenses.removeWhere((item) => item.id == id);
    _changes.add(null);
  }

  @override
  Future<void> applyRemoteExpense(Expense expense) => cacheExpense(expense);

  @override
  Future<void> markSynced(String id, {DateTime? updatedAt}) async {}
}

class _FakeTaskRepository implements TaskRepository {
  final List<TaskItem> tasks = [];
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

  @override
  List<TaskItem> getTasks() => List.unmodifiable(tasks);

  @override
  TaskItem? findById(String id) {
    for (final task in tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  @override
  Future<void> cacheTask(TaskItem task) async {
    tasks.removeWhere((item) => item.id == task.id);
    tasks.add(task);
    _changes.add(null);
  }

  @override
  Future<void> deleteTask(String id) async {
    tasks.removeWhere((item) => item.id == id);
    _changes.add(null);
  }

  @override
  Future<void> applyRemoteTask(TaskItem task) => cacheTask(task);

  @override
  Future<void> markSynced(String id, {DateTime? updatedAt}) async {}
}

class _FakeSyncService implements SyncService {
  @override
  Future<SyncResult> run() async => SyncResult.success;
}

Widget _wrapExpenses(Widget child, ExpenseRepository repository) {
  return MaterialApp(
    home: MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ExpenseRepository>.value(value: repository),
        RepositoryProvider<SyncService>.value(value: _FakeSyncService()),
      ],
      child: child,
    ),
  );
}

Widget _wrapTasks(Widget child, TaskRepository repository) {
  return MaterialApp(
    home: MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TaskRepository>.value(value: repository),
        RepositoryProvider<SyncService>.value(value: _FakeSyncService()),
      ],
      child: child,
    ),
  );
}

void main() {
  testWidgets('expense FAB opens a sheet and saves a local expense', (
    tester,
  ) async {
    final repository = _FakeExpenseRepository();

    await tester.pumpWidget(_wrapExpenses(const ExpensesPage(), repository));
    await tester.pumpAndSettle();

    expect(find.text('No expenses yet'), findsOneWidget);

    await tester.tap(find.byTooltip('Add expense'));
    await tester.pumpAndSettle();
    expect(find.text('Add expense'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Coffee');
    await tester.enterText(find.byType(TextFormField).at(1), '250');
    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();

    expect(repository.expenses, hasLength(1));
    expect(repository.expenses.single.title, 'Coffee');
    expect(repository.expenses.single.amount, 250);
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('No expenses yet'), findsNothing);
  });

  testWidgets('task FAB opens a sheet and saves a local task', (tester) async {
    final repository = _FakeTaskRepository();

    await tester.pumpWidget(_wrapTasks(const TasksPage(), repository));
    await tester.pumpAndSettle();

    expect(find.text('No tasks yet'), findsOneWidget);

    await tester.tap(find.byTooltip('Add task'));
    await tester.pumpAndSettle();
    expect(find.text('Add task'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Pay bills');
    await tester.tap(find.text('Save task'));
    await tester.pumpAndSettle();

    expect(repository.tasks, hasLength(1));
    expect(repository.tasks.single.title, 'Pay bills');
    expect(repository.tasks.single.category, TaskCategory.personal);
    expect(find.text('Pay bills'), findsOneWidget);
    expect(find.text('No tasks yet'), findsNothing);
  });

  testWidgets('expense edit sheet updates the saved record', (tester) async {
    final repository = _FakeExpenseRepository();
    await repository.cacheExpense(
      Expense(
        id: 'expense-1',
        title: 'Coffee',
        amount: 100,
        category: 'Food',
        date: DateTime(2026, 11, 17),
      ),
    );

    await tester.pumpWidget(_wrapExpenses(const ExpensesPage(), repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit expense'));
    await tester.pumpAndSettle();

    expect(find.text('Edit expense'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Lunch');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(repository.expenses, hasLength(1));
    expect(repository.expenses.single.id, 'expense-1');
    expect(repository.expenses.single.title, 'Lunch');
    expect(find.text('Lunch'), findsOneWidget);
  });

  testWidgets('swiping a task away shows undo and restores it', (tester) async {
    final repository = _FakeTaskRepository();
    final task = TaskItem(id: 'task-1', title: 'Pay bills');
    await repository.cacheTask(task);

    await tester.pumpWidget(_wrapTasks(const TasksPage(), repository));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Dismissible), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(repository.tasks, isEmpty);
    expect(find.text('Pay bills deleted'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(repository.tasks, hasLength(1));
    expect(repository.tasks.single.id, 'task-1');
    expect(find.text('Pay bills'), findsOneWidget);
  });
}
