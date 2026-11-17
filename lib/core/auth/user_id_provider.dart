/// Identifies the account whose local records are currently active.
///
/// Hive boxes are opened before login, so records are namespaced by this id
/// rather than by separate boxes. The auth listener updates it on sign-in.
abstract interface class UserIdProvider {
  String? get userId;
}

final class MutableUserIdProvider implements UserIdProvider {
  String? _userId;

  @override
  String? get userId => _userId;

  void set(String? id) => _userId = id;
}

final class FixedUserIdProvider implements UserIdProvider {
  const FixedUserIdProvider(this.userId);

  @override
  final String? userId;
}
