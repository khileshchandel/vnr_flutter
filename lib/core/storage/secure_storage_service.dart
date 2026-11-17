import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// Thin wrapper around flutter_secure_storage so features never depend on the
/// platform plugin directly. Tokens only — never persist passwords.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() =>
      _storage.read(key: AppConstants.accessTokenKey);

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: AppConstants.accessTokenKey, value: token);

  Future<void> deleteAccessToken() =>
      _storage.delete(key: AppConstants.accessTokenKey);

  Future<String?> readRefreshToken() =>
      _storage.read(key: AppConstants.refreshTokenKey);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: AppConstants.refreshTokenKey, value: token);

  Future<void> deleteRefreshToken() =>
      _storage.delete(key: AppConstants.refreshTokenKey);

  Future<void> deleteAllTokens() async {
    await deleteAccessToken();
    await deleteRefreshToken();
  }
}
