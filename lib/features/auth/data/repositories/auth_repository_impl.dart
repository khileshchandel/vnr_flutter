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

    // TODO: validate the token with GET /api/auth/me and return the profile.
    // Until then, a stored token alone is not enough to authenticate.
    return null;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _remote.signIn(email: email, password: password);
    final token = response['token'] as String?;
    final userJson = response['user'];

    if (token == null || token.isEmpty || userJson is! Map<String, dynamic>) {
      throw const AuthFailure('Unexpected sign-in response from server.');
    }

    await _local.cacheToken(token);
    return AppUserModel.fromJson(userJson);
  }

  @override
  Future<void> signOut() => _local.clearToken();
}
