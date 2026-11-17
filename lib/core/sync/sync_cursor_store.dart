import 'package:hive/hive.dart';

import '../auth/user_id_provider.dart';

/// Stores the last successful sync cursor per account and entity type.
abstract interface class SyncCursorStore {
  DateTime? read(String scope);

  Future<void> save(DateTime value, {required String scope});

  Future<void> clear(String scope);
}

final class HiveSyncCursorStore implements SyncCursorStore {
  HiveSyncCursorStore(this._box, this._userId);

  final Box<String> _box;
  final UserIdProvider _userId;

  String _key(String scope) => 'last_sync_${_userId.userId ?? 'local'}_$scope';

  @override
  DateTime? read(String scope) {
    final value = _box.get(_key(scope));
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  @override
  Future<void> save(DateTime value, {required String scope}) =>
      _box.put(_key(scope), value.toIso8601String());

  @override
  Future<void> clear(String scope) => _box.delete(_key(scope));
}
