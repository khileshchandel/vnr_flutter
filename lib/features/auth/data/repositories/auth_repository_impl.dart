import '../../../../core/error/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/app_user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({required this._local, required this._remote});

  final AuthLocalDataSource _local;
  final AuthRemoteDataSource _remote;

  @override
  Future<AppUser?> restoreSession() async {
    final token = await _local.readToken();
    if (token == null || token.isEmpty) return null;

    try {
      final response = await _remote.currentUser(token: token);
      return AppUserModel.fromJson(response);
    } on Failure {
      // Stale or revoked token: drop it and show the login page.
      await _local.clearToken();
      return null;
    }
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _remote.signIn(email: email, password: password);
    return _storeSession(response);
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final response = await _remote.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );
    return _storeSession(response);
  }

  @override
  Future<void> signOut() => _local.clearToken();

  Future<AppUser> _storeSession(Map<String, dynamic> response) async {
    final token = response['token'] as String?;
    final userJson = response['user'];

    if (token == null || token.isEmpty || userJson is! Map<String, dynamic>) {
      throw const AuthFailure('Unexpected response from server.');
    }

    await _local.cacheToken(token);
    return AppUserModel.fromJson(userJson);
  }
}
