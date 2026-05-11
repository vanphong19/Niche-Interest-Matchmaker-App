// lib/features/auth/presentation/bloc/auth_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/auth_user.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<LoginSubmitted>(_onLogin);
    on<RegisterSubmitted>(_onRegister);
    on<ForgotPasswordSubmitted>(_onForgotPassword);
    on<LogoutRequested>(_onLogout);
    on<CheckAuthStatus>(_onCheckAuth);
  }

  User _mapToUser(AuthUser authUser) {
    return User(
      id: authUser.id,
      name: authUser.displayName,
      email: authUser.email,
      avatarUrl:
          'https://api.dicebear.com/7.x/avataaars/svg?seed=${authUser.email}', // ignore: unnecessary_brace_in_string_interps
      createdAt: DateTime.now(),
      isVerified: false,
    );
  }

  Future<void> _onLogin(LoginSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      if (event.email.contains('social@')) {
        // mock social parsing
        final provider = event.email == 'social@google.com'
            ? 'google'
            : 'facebook';
        final authUser = await _authRepository.loginWithSocial(
          provider,
          'social_$provider@nichematch.vn',
          'Social User',
          'social_id_123',
        );
        emit(AuthAuthenticated(_mapToUser(authUser)));
      } else {
        final authUser = await _authRepository.signInWithEmailAndPassword(
          event.email,
          event.password,
        );
        emit(AuthAuthenticated(_mapToUser(authUser)));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegister(
    RegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final authUser = await _authRepository.registerWithEmailAndPassword(
        event.email,
        event.password,
        event.name,
      );
      emit(AuthAuthenticated(_mapToUser(authUser)));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onForgotPassword(
    ForgotPasswordSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      emit(
        const AuthForgotPasswordSuccess(
          'Password reset link sent to your email!',
        ),
      );
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await _authRepository.logout();
    emit(AuthUnauthenticated());
  }

  Future<void> _onCheckAuth(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(_mapToUser(user)));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }
}
