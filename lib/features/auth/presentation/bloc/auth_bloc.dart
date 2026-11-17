import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required this._authRepository}) : super(const AuthState()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
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
  ) {
    return _authenticate(
      emit,
      () =>
          _authRepository.signIn(email: event.email, password: event.password),
    );
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) {
    return _authenticate(
      emit,
      () => _authRepository.signUp(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      ),
    );
  }

  Future<void> _authenticate(
    Emitter<AuthState> emit,
    Future<AppUser> Function() action,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.authenticating,
        clearError: true,
        clearUser: true,
      ),
    );
    try {
      final user = await action();
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: failure.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Could not sign in. Please try again.',
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
