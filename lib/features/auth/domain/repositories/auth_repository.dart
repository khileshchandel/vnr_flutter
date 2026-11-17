import '../entities/app_user.dart';

abstract interface class AuthRepository {
  /// Restores a session from the securely stored token.
  Future<AppUser?> restoreSession();

  Future<AppUser> signIn({required String email, required String password});

  Future<void> signOut();
}
