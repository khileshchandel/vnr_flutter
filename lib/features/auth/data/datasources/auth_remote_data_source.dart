import '../../../../core/network/api_client.dart';

/// Calls the real E Track auth endpoints. Token storage stays in the local
/// data source; this class only talks HTTP.
abstract interface class AuthRemoteDataSource {
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  });

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  Future<Map<String, dynamic>> currentUser({required String token});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) {
    return _apiClient.postJson(
      '/auth/login',
      body: {'email': email, 'password': password},
    );
  }

  @override
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _apiClient.postJson(
      '/auth/register',
      body: {
        'email': email,
        'password': password,
        if (displayName != null && displayName.isNotEmpty)
          'displayName': displayName,
      },
    );
  }

  @override
  Future<Map<String, dynamic>> currentUser({required String token}) {
    return _apiClient.getJson('/auth/me', token: token);
  }
}
