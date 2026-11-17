class AppUser {
  const AppUser({required this.id, required this.email, this.displayName});

  final String id;
  final String email;
  final String? displayName;

  @override
  String toString() => 'AppUser(id: $id, email: $email)';
}
