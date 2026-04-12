import 'package:dio/dio.dart';

class TokenInterceptor extends Interceptor {
  final Dio dio;

  TokenInterceptor(this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add Token to Header
    final token = "YOUR_ACCESS_TOKEN"; // Fetch from secure storage
    options.headers['Authorization'] = 'Bearer $token';
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Logic refresh token here
      final newToken = "NEW_ACCESS_TOKEN"; // Mock logic refresh
      err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
      final response = await dio.fetch(err.requestOptions);
      return handler.resolve(response);
    }
    super.onError(err, handler);
  }
}
