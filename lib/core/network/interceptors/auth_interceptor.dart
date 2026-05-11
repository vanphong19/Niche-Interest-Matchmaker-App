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
          '/api/auth/refresh',
          data: {'refreshToken': refreshToken},
        );

        // Unwrap { success, data: { accessToken, refreshToken } }
        final payload = response.data is Map &&
                (response.data as Map).containsKey('data')
            ? (response.data as Map)['data'] as Map<String, dynamic>
            : response.data as Map<String, dynamic>;

        final newToken = payload['accessToken']?.toString() ?? '';
        final newRefreshToken = payload['refreshToken']?.toString() ?? '';

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
