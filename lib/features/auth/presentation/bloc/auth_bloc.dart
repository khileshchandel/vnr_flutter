import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required this._authRepository}) : super(const AuthState()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
  }

  final AuthRepository _authRepository;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.unknown, clearError: true));
    final user = await _authRepository.restoreSession();
    emit(
      user == null
          ? state.copyWith(status: AuthStatus.unauthenticated, clearUser: true)
          : state.copyWith(status: AuthStatus.authenticated, user: user),
    );
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.authenticating,
        clearError: true,
        clearUser: true,
      ),
    );
    try {
      final user = await _authRepository.signIn(
        email: event.email,
        password: event.password,
      );
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Sign-in is not connected yet. Check back soon.',
        ),
      );
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.signOut();
    emit(
      state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        clearError: true,
      ),
    );
  }
}
