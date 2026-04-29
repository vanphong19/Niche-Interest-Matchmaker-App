// lib/core/network/interceptors/auth_interceptor.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../constants/app_constants.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;
  final Dio _dio;

  AuthInterceptor({
    required FlutterSecureStorage secureStorage,
    required Dio dio,
  })  : _secureStorage = secureStorage,
        _dio = dio;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.read(key: AppConstants.tokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        final refreshToken = await _secureStorage.read(
          key: AppConstants.refreshTokenKey,
        );

        if (refreshToken == null) {
          await _clearTokens();
          return handler.next(err);
        }

        final response = await _dio.post(
          '/auth/refresh',
          data: {'refreshToken': refreshToken},
        );

        final newToken = response.data['accessToken'] as String;
        final newRefreshToken = response.data['refreshToken'] as String;

        await _secureStorage.write(
          key: AppConstants.tokenKey,
          value: newToken,
        );
        await _secureStorage.write(
          key: AppConstants.refreshTokenKey,
          value: newRefreshToken,
        );

        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        final retryResponse = await _dio.fetch(err.requestOptions);
        return handler.resolve(retryResponse);
      } catch (_) {
        await _clearTokens();
        return handler.next(err);
      }
    }
    super.onError(err, handler);
  }

  Future<void> _clearTokens() async {
    await _secureStorage.delete(key: AppConstants.tokenKey);
    await _secureStorage.delete(key: AppConstants.refreshTokenKey);
  }
}
