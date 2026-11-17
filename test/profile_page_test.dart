import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_track/features/auth/domain/entities/app_user.dart';
import 'package:e_track/features/auth/domain/repositories/auth_repository.dart';
import 'package:e_track/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:e_track/features/auth/presentation/bloc/auth_event.dart';
import 'package:e_track/features/profile/presentation/pages/profile_page.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository()
    : _user = const AppUser(
        id: 'u1',
        email: 'sagar@example.com',
        displayName: 'Sagar',
      );

  final AppUser _user;
  int signOutCalls = 0;

  @override
  Future<AppUser?> restoreSession() async => _user;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async => _user;

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async => _user;

  @override
  Future<void> signOut() async => signOutCalls++;
}

void main() {
  testWidgets('profile shows the user and asks before signing out', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    final bloc = AuthBloc(authRepository: repository);
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: bloc..add(const AuthCheckRequested()),
          child: const ProfilePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sagar'), findsOneWidget);
    expect(find.text('sagar@example.com'), findsOneWidget);
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsNothing);
    expect(repository.signOutCalls, 0);

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(repository.signOutCalls, 1);
  });
}
