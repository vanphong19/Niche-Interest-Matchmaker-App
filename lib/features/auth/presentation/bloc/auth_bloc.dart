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
    on<SocialLoginSubmitted>(_onSocialLogin);
    on<RegisterSubmitted>(_onRegister);
    on<ForgotPasswordSubmitted>(_onForgotPassword);
    on<LogoutRequested>(_onLogout);
    on<CheckAuthStatus>(_onCheckAuth);
    on<SendOtpRequested>(_onSendOtp);
    on<ResetPasswordSubmitted>(_onResetPassword);
  }

  User _mapToUser(AuthUser authUser) {
    return User(
      id: authUser.id,
      name: authUser.displayName,
      email: authUser.email,
      avatarUrl: '',
      createdAt: DateTime.now(),
      isVerified: false,
    );
  }

  Future<void> _onLogin(LoginSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final authUser = await _authRepository.signInWithEmailAndPassword(
        event.email,
        event.password,
      );
      emit(AuthAuthenticated(_mapToUser(authUser)));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSocialLogin(
    SocialLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final authUser = await _authRepository.loginWithSocial(
        event.provider,
        event.email,
        event.displayName,
        event.providerId,
      );
      emit(AuthAuthenticated(_mapToUser(authUser)));
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
        event.verificationCode,
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
      await _authRepository.forgotPassword(event.email);
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

  Future<void> _onSendOtp(
    SendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.sendSignUpOtp(event.email);
      emit(AuthOtpSentSuccess(event.email));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onResetPassword(
    ResetPasswordSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.resetPassword(
        event.email,
        event.code,
        event.newPassword,
      );
      emit(const AuthResetPasswordSuccess('Đặt lại mật khẩu thành công! Hãy đăng nhập bằng mật khẩu mới.'));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
