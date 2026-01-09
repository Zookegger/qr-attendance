import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_attendance_frontend/src/blocs/auth/auth_event.dart';
import 'package:qr_attendance_frontend/src/blocs/auth/auth_state.dart';
import 'package:qr_attendance_frontend/src/services/auth.service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthenticationService _authService;

  AuthBloc({
    AuthenticationService? authService,
  })  : _authService = authService ?? AuthenticationService(),
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthTokenRefreshRequested>(_onAuthTokenRefreshRequested);
    on<AuthForgotPasswordRequested>(_onAuthForgotPasswordRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authService.getCachedUser();
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final success = await _authService.logout();
      if (success) {
        emit(const AuthUnauthenticated());
      } else {
        emit(const AuthError(message: 'Logout failed'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthTokenRefreshRequested(
    AuthTokenRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final session = await _authService.refresh();
      emit(AuthAuthenticated(user: session.user));
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthForgotPasswordRequested(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authService.sendPasswordResetEmail(event.email);
      emit(
        const AuthForgotPasswordSuccess(
          message: 'Password reset link sent to your email',
        ),
      );
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }
}
