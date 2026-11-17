import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:e_track/core/error/failures.dart';
import 'package:e_track/core/network/token_provider.dart';
import 'package:e_track/core/sync/sync_coordinator.dart';
import 'package:e_track/core/sync/sync_cursor_store.dart';
import 'package:e_track/core/sync/sync_outbox.dart';
import 'package:e_track/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:e_track/features/expenses/data/datasources/expense_remote_data_source.dart';
import 'package:e_track/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:e_track/features/expenses/domain/entities/expense.dart';
import 'package:e_track/features/tasks/data/datasources/task_local_data_source.dart';
import 'package:e_track/features/tasks/data/datasources/task_remote_data_source.dart';
import 'package:e_track/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:e_track/features/tasks/domain/entities/task_item.dart';

final _updatedAt = DateTime.utc(2026, 11, 17, 12);

class _MemoryOutbox implements SyncOutbox {
  final List<PendingSyncOperation> operations = [];
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

  @override
  List<PendingSyncOperation> readAll() => List.unmodifiable(operations);

  @override
  bool hasPending(String recordId) =>
      operations.any((operation) => operation.recordId == recordId);

  @override
  Future<void> enqueue({
    required SyncOperationKind kind,
    required String recordId,
  }) async {
    operations.removeWhere(
      (operation) => operation.recordId == recordId && operation.kind == kind,
    );
    operations.add(
      PendingSyncOperation(
        id: 'op-${operations.length}',
        kind: kind,
        recordId: recordId,
        ownerId: 'user-1',
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> remove(String operationId) async {
    operations.removeWhere((operation) => operation.id == operationId);
  }
}

class _MemoryCursor implements SyncCursorStore {
  final Map<String, DateTime> values = {};

  @override
  DateTime? read(String scope) => values[scope];

  @override
  Future<void> save(DateTime value, {required String scope}) async {
    values[scope] = value;
  }

  @override
  Future<void> clear(String scope) async => values.remove(scope);
}

class _MemoryExpenses implements ExpenseLocalDataSource {
  final Map<String, Expense> records = {};

  @override
  List<Expense> getExpenses() => records.values.toList();

  @override
  Expense? find(String id) => records[id];

  @override
  Future<void> put(Expense expense) async => records[expense.id] = expense;

  @override
  Future<void> remove(String id) async => records.remove(id);
}

class _MemoryTasks implements TaskLocalDataSource {
  final Map<String, TaskItem> records = {};

  @override
  List<TaskItem> getTasks() => records.values.toList();

  @override
  TaskItem? find(String id) => records[id];

  @override
  Future<void> put(TaskItem task) async => records[task.id] = task;

  @override
  Future<void> remove(String id) async => records.remove(id);
}

class _FakeExpenseRemote implements ExpenseRemoteDataSource {
  List<Expense> fetched = [];
  Object? upsertError;

  int upsertCalls = 0;
  int deleteCalls = 0;

  @override
  Future<List<Expense>> fetch({
    required String token,
    DateTime? updatedAfter,
    int limit = 200,
  }) async => fetched;

  @override
  Future<Expense> upsert({
    required String token,
    required Expense expense,
  }) async {
    upsertCalls++;
    if (upsertError != null) throw upsertError!;
    return expense.copyWith(isSynced: true, updatedAt: _updatedAt);
  }

  @override
  Future<bool> delete({required String token, required String id}) async {
    deleteCalls++;
    return true;
  }
}

class _FakeTaskRemote implements TaskRemoteDataSource {
  List<TaskItem> fetched = [];

  @override
  Future<List<TaskItem>> fetch({
    required String token,
    DateTime? updatedAfter,
    int limit = 200,
  }) async => fetched;

  @override
  Future<TaskItem> upsert({
    required String token,
    required TaskItem task,
  }) async => task.copyWith(isSynced: true, updatedAt: _updatedAt);

  @override
  Future<bool> delete({required String token, required String id}) async =>
      true;
}

class _Harness {
  _Harness() {
    expenses = ExpenseRepositoryImpl(expenseLocal, outbox);
    tasks = TaskRepositoryImpl(taskLocal, outbox);
    sync = SyncCoordinator(
      tokenProvider: _Token(token),
      expenses: expenses,
      tasks: tasks,
      expenseRemote: expenseRemote,
      taskRemote: taskRemote,
      outbox: outbox,
      cursorStore: cursor,
    );
  }

  final String token = 'test-token';
  final outbox = _MemoryOutbox();
  final cursor = _MemoryCursor();
  final expenseLocal = _MemoryExpenses();
  final taskLocal = _MemoryTasks();
  final expenseRemote = _FakeExpenseRemote();
  final taskRemote = _FakeTaskRemote();
  late final ExpenseRepositoryImpl expenses;
  late final TaskRepositoryImpl tasks;
  late final SyncCoordinator sync;
}

class _Token implements TokenProvider {
  const _Token(this.value);

  final String? value;

  @override
  Future<String?> readAccessToken() async => value;
}

Expense _expense(String id, {bool isSynced = false}) => Expense(
  id: id,
  title: 'Coffee',
  amount: 120,
  category: 'Food',
  date: DateTime.utc(2026, 11, 17),
  isSynced: isSynced,
);

void main() {
  test('a local write queues an upsert and upload clears the outbox', () async {
    final harness = _Harness();
    await harness.expenses.cacheExpense(_expense('expense-1'));

    expect(harness.outbox.readAll(), hasLength(1));
    expect(harness.expenseLocal.records['expense-1']!.isSynced, isFalse);

    final result = await harness.sync.run();

    expect(result, SyncResult.success);
    expect(harness.expenseRemote.upsertCalls, 1);
    expect(harness.outbox.readAll(), isEmpty);
    expect(harness.expenseLocal.records['expense-1']!.isSynced, isTrue);
    expect(harness.expenseLocal.records['expense-1']!.updatedAt, _updatedAt);
  });

  test('offline uploads keep the record in the outbox', () async {
    final harness = _Harness();
    await harness.expenses.cacheExpense(_expense('expense-2'));
    harness.expenseRemote.upsertError = const NetworkFailure('No connection');

    final result = await harness.sync.run();

    expect(result, SyncResult.offline);
    expect(harness.outbox.readAll(), hasLength(1));
    expect(harness.expenseLocal.records.containsKey('expense-2'), isTrue);
  });

  test(
    'deletes drain the outbox and tombstones remove synced local records',
    () async {
      final harness = _Harness();
      await harness.tasks.cacheTask(TaskItem(id: 'task-1', title: 'Pay bills'));
      await harness.sync.run();
      expect(harness.taskRemote.fetched, isEmpty);

      await harness.tasks.deleteTask('task-1');
      expect(harness.taskLocal.records, isEmpty);

      final result = await harness.sync.run();
      expect(result, SyncResult.success);
      expect(harness.outbox.readAll(), isEmpty);

      // Another device deleted a synced expense; the tombstone is applied.
      await harness.expenses.applyRemoteExpense(
        _expense('expense-3', isSynced: true),
      );
      harness.expenseRemote.fetched = [
        _expense(
          'expense-3',
          isSynced: true,
        ).copyWith(updatedAt: _updatedAt, deletedAt: _updatedAt),
      ];

      await harness.sync.run();

      expect(harness.expenseLocal.records, isEmpty);
    },
  );
}
