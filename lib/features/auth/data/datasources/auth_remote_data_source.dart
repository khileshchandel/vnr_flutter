/// Contract for the E Track API auth endpoints.
///
/// Implementation is intentionally deferred to the API integration phase;
/// see API.md in the Deno project for the planned request/response shapes.
abstract interface class AuthRemoteDataSource {
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl();

  @override
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError(
      'Wire POST /api/auth/login to AppConstants.apiBaseUrl in the API phase.',
    );
  }
}
