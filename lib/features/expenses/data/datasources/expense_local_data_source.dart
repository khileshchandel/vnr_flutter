import 'package:hive/hive.dart';

import '../../../../core/auth/user_id_provider.dart';
import '../../../../core/storage/hive_service.dart';
import '../../domain/entities/expense.dart';

/// Hive-backed local store. Reads are scoped to the signed-in account.
abstract interface class ExpenseLocalDataSource {
  List<Expense> getExpenses();

  Expense? find(String id);

  Future<void> put(Expense expense);

  Future<void> remove(String id);
}

class ExpenseLocalDataSourceImpl implements ExpenseLocalDataSource {
  ExpenseLocalDataSourceImpl(this._box, this._userId);

  final Box _box;
  final UserIdProvider _userId;

  String get _prefix => '${_userId.userId ?? 'local'}::';
  String _key(String id) => '$_prefix$id';

  Map<String, dynamic>? _read(String key) {
    final raw = _box.get(key);
    return raw == null ? null : HiveService.stringMap(raw);
  }

  @override
  List<Expense> getExpenses() {
    final expenses = _box.keys
        .whereType<String>()
        .where((key) => key.startsWith(_prefix))
        .map((key) => Expense.fromJson(_read(key)!))
        .toList();
    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }

  @override
  Expense? find(String id) {
    final json = _read(_key(id));
    return json == null ? null : Expense.fromJson(json);
  }

  @override
  Future<void> put(Expense expense) =>
      _box.put(_key(expense.id), expense.toJson());

  @override
  Future<void> remove(String id) => _box.delete(_key(id));
}
