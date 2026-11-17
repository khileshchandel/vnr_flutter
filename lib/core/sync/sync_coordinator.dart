import '../error/failures.dart';
import '../network/token_provider.dart';
import '../../features/expenses/data/datasources/expense_remote_data_source.dart';
import '../../features/expenses/domain/repositories/expense_repository.dart';
import '../../features/tasks/data/datasources/task_remote_data_source.dart';
import '../../features/tasks/domain/repositories/task_repository.dart';
import 'sync_cursor_store.dart';
import 'sync_outbox.dart';

enum SyncResult { success, noSession, alreadyRunning, offline, unauthorized }

/// Presentation-facing handle for manual refresh and startup sync.
abstract interface class SyncService {
  Future<SyncResult> run();
}

/// Local writes are never blocked on the network: the outbox is drained first,
/// then remote changes are pulled into Hive using per-entity cursors.
final class SyncCoordinator implements SyncService {
  SyncCoordinator({
    required this.tokenProvider,
    required this.expenses,
    required this.tasks,
    required this.expenseRemote,
    required this.taskRemote,
    required this.outbox,
    required this.cursorStore,
  });

  final TokenProvider tokenProvider;
  final ExpenseRepository expenses;
  final TaskRepository tasks;
  final ExpenseRemoteDataSource expenseRemote;
  final TaskRemoteDataSource taskRemote;
  final SyncOutbox outbox;
  final SyncCursorStore cursorStore;

  static const _pageSize = 200;
  static const _maxPages = 20;

  bool _running = false;

  @override
  Future<SyncResult> run() async {
    if (_running) return SyncResult.alreadyRunning;
    final token = await tokenProvider.readAccessToken();
    if (token == null || token.isEmpty) return SyncResult.noSession;

    _running = true;
    try {
      await _drainOutbox(token);
      await _pullRemote(token);
      return SyncResult.success;
    } on AuthFailure {
      return SyncResult.unauthorized;
    } on Failure {
      return SyncResult.offline;
    } catch (_) {
      return SyncResult.offline;
    } finally {
      _running = false;
    }
  }

  Future<void> _drainOutbox(String token) async {
    for (final operation in outbox.readAll()) {
      switch (operation.kind) {
        case SyncOperationKind.upsertExpense:
          final expense = expenses.findById(operation.recordId);
          if (expense == null) {
            await outbox.remove(operation.id);
            break;
          }
          final saved = await expenseRemote.upsert(
            token: token,
            expense: expense,
          );
          await expenses.markSynced(saved.id, updatedAt: saved.updatedAt);
          await outbox.remove(operation.id);
          break;

        case SyncOperationKind.upsertTask:
          final task = tasks.findById(operation.recordId);
          if (task == null) {
            await outbox.remove(operation.id);
            break;
          }
          final saved = await taskRemote.upsert(token: token, task: task);
          await tasks.markSynced(saved.id, updatedAt: saved.updatedAt);
          await outbox.remove(operation.id);
          break;

        case SyncOperationKind.deleteExpense:
          await expenseRemote.delete(token: token, id: operation.recordId);
          await outbox.remove(operation.id);
          break;

        case SyncOperationKind.deleteTask:
          await taskRemote.delete(token: token, id: operation.recordId);
          await outbox.remove(operation.id);
          break;
      }
    }
  }

  Future<void> _pullRemote(String token) async {
    var expenseCursor = cursorStore.read('expenses');
    var taskCursor = cursorStore.read('tasks');

    for (var page = 0; page < _maxPages; page++) {
      final incomingExpenses = await expenseRemote.fetch(
        token: token,
        updatedAfter: expenseCursor,
        limit: _pageSize,
      );
      final incomingTasks = await taskRemote.fetch(
        token: token,
        updatedAfter: taskCursor,
        limit: _pageSize,
      );

      if (incomingExpenses.isEmpty && incomingTasks.isEmpty) break;

      for (final expense in incomingExpenses) {
        await expenses.applyRemoteExpense(expense);
      }
      for (final task in incomingTasks) {
        await tasks.applyRemoteTask(task);
      }

      expenseCursor =
          _advance(incomingExpenses.map((e) => e.updatedAt ?? e.date)) ??
          expenseCursor;
      taskCursor =
          _advance(
            incomingTasks.map((t) => t.updatedAt).whereType<DateTime>(),
          ) ??
          taskCursor;

      if (incomingExpenses.length < _pageSize &&
          incomingTasks.length < _pageSize) {
        break;
      }
    }

    if (expenseCursor != null) {
      await cursorStore.save(expenseCursor, scope: 'expenses');
    }
    if (taskCursor != null) {
      await cursorStore.save(taskCursor, scope: 'tasks');
    }
  }

  DateTime? _advance(Iterable<DateTime> candidates) {
    DateTime? latest;
    for (final candidate in candidates) {
      if (latest == null || candidate.isAfter(latest)) latest = candidate;
    }
    return latest;
  }
}
