// lib/features/auth/presentation/bloc/auth_event.dart
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  const LoginSubmitted(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

// Keep backward compat alias
class LoginRequested extends LoginSubmitted {
  const LoginRequested(super.email, super.password);
}

class SocialLoginSubmitted extends AuthEvent {
  final String provider;
  final String email;
  final String displayName;
  final String providerId;

  const SocialLoginSubmitted({
    required this.provider,
    required this.email,
    required this.displayName,
    required this.providerId,
  });

  @override
  List<Object?> get props => [provider, email, displayName, providerId];
}

class RegisterSubmitted extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String verificationCode;

  const RegisterSubmitted(this.name, this.email, this.password, this.verificationCode);

  @override
  List<Object?> get props => [name, email, password, verificationCode];
}

// Keep backward compat alias
class RegisterRequested extends RegisterSubmitted {
  const RegisterRequested(super.name, super.email, super.password, super.verificationCode);
}

class ForgotPasswordSubmitted extends AuthEvent {
  final String email;

  const ForgotPasswordSubmitted(this.email);

  @override
  List<Object?> get props => [email];
}

class LogoutRequested extends AuthEvent {}

class CheckAuthStatus extends AuthEvent {}

class SendOtpRequested extends AuthEvent {
  final String email;

  const SendOtpRequested(this.email);

  @override
  List<Object?> get props => [email];
}

class ResetPasswordSubmitted extends AuthEvent {
  final String email;
  final String code;
  final String newPassword;

  const ResetPasswordSubmitted({
    required this.email,
    required this.code,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [email, code, newPassword];
}
