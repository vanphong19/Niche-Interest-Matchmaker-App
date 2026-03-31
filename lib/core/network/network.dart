import 'package:dio/dio.dart';

import '../constants/constants.dart';

class NetworkConfig {
  NetworkConfig._();

  static Dio createDio({String baseUrl = ''}) {
    final options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      sendTimeout: AppConstants.sendTimeout,
      responseType: ResponseType.json,
      contentType: Headers.jsonContentType,
      headers: const {Headers.acceptHeader: Headers.jsonContentType},
    );

    final dio = Dio(options);
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));

    return dio;
  }
}
