// lib/core/errors/exceptions.dart

class ServerException implements Exception {
  const ServerException({this.message = 'Server error', this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ServerException: $message (status: $statusCode)';
}

class NetworkException implements Exception {
  const NetworkException({this.message = 'No internet connection'});

  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

class AuthException implements Exception {
  const AuthException({this.message = 'Authentication error'});

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

class CacheException implements Exception {
  const CacheException({this.message = 'Cache error'});

  final String message;

  @override
  String toString() => 'CacheException: $message';
}

class NotFoundException implements Exception {
  const NotFoundException({this.message = 'Resource not found'});

  final String message;

  @override
  String toString() => 'NotFoundException: $message';
}

class ValidationException implements Exception {
  const ValidationException({
    this.message = 'Validation error',
    this.fieldErrors = const {},
  });

  final String message;
  final Map<String, String> fieldErrors;

  @override
  String toString() => 'ValidationException: $message';
}

class TimeoutException implements Exception {
  const TimeoutException({this.message = 'Request timed out'});

  final String message;

  @override
  String toString() => 'TimeoutException: $message';
}
