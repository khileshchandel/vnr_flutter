sealed class AuthEvent {
  const AuthEvent();
}

final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

final class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({required this.email, required this.password});

  final String email;
  final String password;
}

final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}
