import '../entities/app_user.dart';

abstract interface class AuthRepository {
  /// Restores a session by validating the securely stored token with the API.
  Future<AppUser?> restoreSession();

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  Future<void> signOut();
}
