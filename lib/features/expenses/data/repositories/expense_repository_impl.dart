import 'dart:async';

import '../../../../core/sync/sync_outbox.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_local_data_source.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  ExpenseRepositoryImpl(this._local, this._outbox);

  final ExpenseLocalDataSource _local;
  final SyncOutbox _outbox;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

  @override
  List<Expense> getExpenses() => _local.getExpenses();

  @override
  Expense? findById(String id) => _local.find(id);

  @override
  Future<void> cacheExpense(Expense expense) async {
    await _local.put(expense.copyWith(isSynced: false, clearDeletedAt: true));
    await _outbox.enqueue(
      kind: SyncOperationKind.upsertExpense,
      recordId: expense.id,
    );
    _changes.add(null);
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _local.remove(id);
    await _outbox.enqueue(kind: SyncOperationKind.deleteExpense, recordId: id);
    _changes.add(null);
  }

  @override
  Future<void> applyRemoteExpense(Expense expense) async {
    // Local edits always win until they have been acknowledged by the server.
    if (_outbox.hasPending(expense.id)) return;
    final local = _local.find(expense.id);
    if (local != null && !local.isSynced) return;

    if (expense.deletedAt != null) {
      await _local.remove(expense.id);
    } else {
      await _local.put(expense.copyWith(isSynced: true));
    }
    _changes.add(null);
  }

  @override
  Future<void> markSynced(String id, {DateTime? updatedAt}) async {
    final local = _local.find(id);
    if (local == null) return;
    await _local.put(
      local.copyWith(
        isSynced: true,
        updatedAt: updatedAt,
        clearDeletedAt: true,
      ),
    );
    _changes.add(null);
  }
}
