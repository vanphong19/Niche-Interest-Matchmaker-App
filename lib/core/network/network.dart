// lib/core/network/network.dart
import 'package:dio/dio.dart';

import '../constants/app_constants.dart';

export 'dio_client.dart';
export 'network_info.dart';
export 'interceptors/auth_interceptor.dart';
export 'interceptors/mock_interceptor.dart';

/// Backward-compatible NetworkConfig class.
/// New code should use [DioClient] instead.
class NetworkConfig {
  NetworkConfig._();

  static Dio createDio({String baseUrl = ''}) {
    final options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      sendTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
      contentType: Headers.jsonContentType,
      headers: const {Headers.acceptHeader: Headers.jsonContentType},
    );

    final dio = Dio(options);
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));

    return dio;
  }
}
