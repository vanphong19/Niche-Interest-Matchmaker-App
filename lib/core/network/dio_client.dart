// lib/core/network/dio_client.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';
import '../constants/api_constants.dart';
import '../errors/failures.dart';
import '../errors/exceptions.dart';
import 'interceptors/auth_interceptor.dart';

class DioClient {
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  DioClient({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        sendTimeout: AppConstants.sendTimeout,
        responseType: ResponseType.json,
        contentType: Headers.jsonContentType,
        headers: {Headers.acceptHeader: Headers.jsonContentType},
      ),
    );

    _dio.interceptors.add(
      AuthInterceptor(secureStorage: _secureStorage, dio: _dio),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: false,
          responseHeader: false,
          error: true,
        ),
      );
    }
  }

  Dio get dio => _dio;

  // ─── GET ────────────────────────────────────────────────────────
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ─── POST ───────────────────────────────────────────────────────
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ─── PUT ────────────────────────────────────────────────────────
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ─── PATCH ──────────────────────────────────────────────────────
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ─── DELETE ─────────────────────────────────────────────────────
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ─── Exception Mapping ──────────────────────────────────────────
  Exception _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        return _mapStatusCode(e.response?.statusCode, e.response?.data);
      case DioExceptionType.cancel:
        return const ServerException(message: 'Request cancelled');
      default:
        return const ServerException();
    }
  }

  Exception _mapStatusCode(int? statusCode, dynamic data) {
    final message = data is Map ? (data['message'] as String?) ?? '' : '';
    switch (statusCode) {
      case 400:
        return ValidationException(
          message: message.isNotEmpty ? message : 'Bad request',
        );
      case 401:
        return AuthException(
          message: message.isNotEmpty ? message : 'Unauthorized',
        );
      case 403:
        return const AuthException(message: 'Access denied');
      case 404:
        return NotFoundException(
          message: message.isNotEmpty ? message : 'Not found',
        );
      case 409:
        return ServerException(
          message: message.isNotEmpty ? message : 'Conflict',
          statusCode: 409,
        );
      case 422:
        return ValidationException(
          message: message.isNotEmpty ? message : 'Unprocessable entity',
        );
      case 429:
        return const ServerException(
          message: 'Too many requests. Please slow down.',
          statusCode: 429,
        );
      case 500:
      case 502:
      case 503:
        return ServerException(
          message: message.isNotEmpty ? message : 'Server error',
          statusCode: statusCode,
        );
      default:
        return ServerException(
          message: message.isNotEmpty ? message : 'An error occurred',
          statusCode: statusCode,
        );
    }
  }

  // ─── Helper: Map exceptions to Failures ─────────────────────────
  static Failure mapExceptionToFailure(Object e) {
    if (e is NetworkException) {
      return NetworkFailure(e.message);
    } else if (e is AuthException) {
      return AuthFailure(e.message);
    } else if (e is NotFoundException) {
      return NotFoundFailure(e.message);
    } else if (e is ValidationException) {
      return ValidationFailure(e.message);
    } else if (e is TimeoutException) {
      return TimeoutFailure(e.message);
    } else if (e is ServerException) {
      return ServerFailure(e.message, e.statusCode);
    } else {
      return const UnexpectedFailure();
    }
  }
}
