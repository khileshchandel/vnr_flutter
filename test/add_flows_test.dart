import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

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
  Future<void> cacheExpense(Expense expense) async {
    expenses.add(expense);
    _changes.add(null);
  }
}

class _FakeTaskRepository implements TaskRepository {
  final List<TaskItem> tasks = [];
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

  @override
  List<TaskItem> getTasks() => List.unmodifiable(tasks);

  @override
  Future<void> cacheTask(TaskItem task) async {
    tasks.add(task);
    _changes.add(null);
  }
}

void main() {
  testWidgets('expense FAB opens a sheet and saves a local expense', (
    tester,
  ) async {
    final repository = _FakeExpenseRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: RepositoryProvider<ExpenseRepository>.value(
          value: repository,
          child: const ExpensesPage(),
        ),
      ),
    );
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

    await tester.pumpWidget(
      MaterialApp(
        home: RepositoryProvider<TaskRepository>.value(
          value: repository,
          child: const TasksPage(),
        ),
      ),
    );
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
}
