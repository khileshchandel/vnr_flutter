import '../storage/secure_storage_service.dart';

/// Abstraction over token access so API clients can be tested without plugins.
abstract interface class TokenProvider {
  Future<String?> readAccessToken();
}

class SecureTokenProvider implements TokenProvider {
  const SecureTokenProvider(this._storage);

  final SecureStorageService _storage;

  @override
  Future<String?> readAccessToken() => _storage.readAccessToken();
}
