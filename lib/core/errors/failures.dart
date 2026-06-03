// lib/core/errors/failures.dart
import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure(this.message, {this.code});

  final String message;
  final int? code;

  @override
  List<Object?> get props => [message, code];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection. Please check your network.']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred. Please try again later.', int? code])
      : super(code: code);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed. Please log in again.']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'The requested resource was not found.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation error. Please check your input.']);

  final Map<String, String> fieldErrors = const {};
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Failed to load cached data.']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission denied.']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Request timed out. Please try again.']);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'An unexpected error occurred.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Unknown failure']);
}
