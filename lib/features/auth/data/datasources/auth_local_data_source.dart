import '../../../../core/storage/secure_storage_service.dart';

abstract interface class AuthLocalDataSource {
  Future<String?> readToken();

  Future<void> cacheToken(String token);

  Future<void> clearToken();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  const AuthLocalDataSourceImpl(this._storage);

  final SecureStorageService _storage;

  @override
  Future<String?> readToken() => _storage.readAccessToken();

  @override
  Future<void> cacheToken(String token) => _storage.saveAccessToken(token);

  @override
  Future<void> clearToken() => _storage.deleteAccessToken();
}
