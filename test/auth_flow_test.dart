import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:e_track/core/error/failures.dart';
import 'package:e_track/core/network/api_client.dart';
import 'package:e_track/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:e_track/features/auth/domain/entities/app_user.dart';
import 'package:e_track/features/auth/domain/repositories/auth_repository.dart';
import 'package:e_track/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:e_track/features/auth/presentation/bloc/auth_event.dart';
import 'package:e_track/features/auth/presentation/bloc/auth_state.dart';

class _FailingAuthRepository implements AuthRepository {
  const _FailingAuthRepository();

  @override
  Future<AppUser?> restoreSession() async => null;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    throw const AuthFailure('Invalid email or password.');
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    throw const AuthFailure('Could not create the account.');
  }

  @override
  Future<void> signOut() async {}
}

AuthRemoteDataSource _dataSource(MockClient client) => AuthRemoteDataSourceImpl(
  ApiClient(client: client, baseUrl: 'http://localhost:8000'),
);

void main() {
  test('signIn posts credentials to /api/auth/login', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/auth/login');
      expect(jsonDecode(request.body), {
        'email': 'user@example.com',
        'password': 'secret123',
      });

      return http.Response(
        jsonEncode({
          'token': 'abc',
          'user': {'id': 'u1', 'email': 'user@example.com'},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final response = await _dataSource(client)
        .signIn(email: 'user@example.com', password: 'secret123');

    expect(response['token'], 'abc');
    expect(response['user']['id'], 'u1');
    client.close();
  });

  test('signUp posts to /api/auth/register with an optional name', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/auth/register');
      expect(jsonDecode(request.body), {
        'email': 'new@example.com',
        'password': 'secret123',
        'displayName': 'New User',
      });

      return http.Response(
        jsonEncode({
          'token': 'abc',
          'user': {'id': 'u2', 'email': 'new@example.com', 'name': 'New User'},
        }),
        201,
        headers: {'content-type': 'application/json'},
      );
    });

    final response = await _dataSource(client).signUp(
      email: 'new@example.com',
      password: 'secret123',
      displayName: 'New User',
    );

    expect(response['token'], 'abc');
    client.close();
  });

  test('bad credentials surface the API message as an AuthFailure', () async {
    final client = MockClient((_) async {
      return http.Response(
        jsonEncode({
          'error': {
            'code': 'INVALID_CREDENTIALS',
            'message': 'Invalid email or password.',
          },
        }),
        401,
        headers: {'content-type': 'application/json'},
      );
    });

    await expectLater(
      _dataSource(client)
          .signIn(email: 'user@example.com', password: 'wrong-one'),
      throwsA(
        isA<AuthFailure>().having(
          (failure) => failure.message,
          'message',
          'Invalid email or password.',
        ),
      ),
    );
    client.close();
  });

  test('currentUser sends the stored bearer token', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/auth/me');
      expect(request.headers['Authorization'], 'Bearer saved-token');
      return http.Response(
        jsonEncode({'id': 'u1', 'email': 'user@example.com'}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final response = await _dataSource(client)
        .currentUser(token: 'saved-token');
    expect(response['id'], 'u1');
    client.close();
  });

  test('AuthBloc surfaces the sign-in error message', () async {
    final bloc = AuthBloc(authRepository: const _FailingAuthRepository());
    final failed = bloc.stream.firstWhere(
      (state) => state.errorMessage != null,
    );

    bloc.add(
      const AuthSignInRequested(
        email: 'user@example.com',
        password: 'wrong-one',
      ),
    );

    final state = await failed;
    expect(state.status, AuthStatus.unauthenticated);
    expect(state.errorMessage, 'Invalid email or password.');
    await bloc.close();
  });
}
