import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/auth_user.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dio);

  final Dio _dio;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  // ─── Helpers ────────────────────────────────────────────────────────
  /// Backend wraps responses in { success: bool, data: {...} } via ResponseWrapperMiddleware.
  /// This helper safely unwraps the nested data.
  Map<String, dynamic> _unwrap(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      // Check if wrapped: { success: true, data: { ... } }
      if (responseData.containsKey('data') && responseData['data'] is Map<String, dynamic>) {
        return responseData['data'] as Map<String, dynamic>;
      }
      return responseData;
    }
    return {};
  }

  AuthUser _parseLoginData(Map<String, dynamic> payload) {
    final token = payload['accessToken']?.toString() ?? '';
    final refreshToken = payload['refreshToken']?.toString() ?? '';
    saveToken(token, refreshToken); // fire and forget

    final userJson = payload['user'] as Map<String, dynamic>? ?? {};
    return AuthUser(
      id: userJson['id']?.toString() ?? '',
      email: userJson['email']?.toString() ?? '',
      displayName:
          userJson['name']?.toString() ??
          userJson['displayName']?.toString() ??
          'User',
    );
  }

  // ─── Email / Password Auth ──────────────────────────────────────────
  @override
  Future<AuthUser> signInWithEmailAndPassword(String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );
      final payload = _unwrap(response.data);
      return _parseLoginData(payload);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Email hoặc mật khẩu không đúng');
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        throw Exception(
            'Không thể kết nối server. Kiểm tra backend đang chạy tại port 5230.');
      }
      final msg = _unwrap(e.response?.data)['message']?.toString() ??
          e.message ??
          'Lỗi không xác định';
      throw Exception('Đăng nhập thất bại: $msg');
    }
  }

  @override
  Future<AuthUser> registerWithEmailAndPassword(
      String email, String password, String displayName) async {
    try {
      final response = await _dio.post(
        '/api/auth/register',
        data: {'email': email, 'password': password, 'displayName': displayName},
      );
      final payload = _unwrap(response.data);
      return _parseLoginData(payload);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final msg = _unwrap(e.response?.data)['message']?.toString() ??
            'Email đã tồn tại';
        throw Exception(msg);
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        throw Exception('Không thể kết nối server.');
      }
      throw Exception(
          'Đăng ký thất bại: ${_unwrap(e.response?.data)['message'] ?? e.message}');
    }
  }

  // ─── Social Auth ────────────────────────────────────────────────────
  @override
  Future<AuthUser> loginWithSocial(
      String provider, String email, String displayName, String providerId) async {
    try {
      final response = await _dio.post(
        '/api/auth/social',
        data: {
          'provider': provider,
          'email': email,
          'providerId': providerId,
          'displayName': displayName,
        },
      );
      final payload = _unwrap(response.data);
      return _parseLoginData(payload);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        throw Exception('Không thể kết nối server để đăng nhập $provider.');
      }
      throw Exception(
          'Đăng nhập $provider thất bại: ${_unwrap(e.response?.data)['message'] ?? e.message}');
    }
  }

  // ─── Session ────────────────────────────────────────────────────────
  @override
  Future<AuthUser?> getCurrentUser() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return null;

    try {
      final response = await _dio.get('/api/auth/me');
      final userJson = _unwrap(response.data);
      return AuthUser(
        id: userJson['id']?.toString() ?? '',
        email: userJson['email']?.toString() ?? '',
        displayName: userJson['name']?.toString() ?? 'User',
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> signOut() async => logout();

  @override
  Future<String?> getToken() async => secureStorage.read(key: 'jwt_token');

  @override
  Future<void> saveToken(String token, String refreshToken) async {
    await secureStorage.write(key: 'jwt_token', value: token);
    await secureStorage.write(key: 'refresh_token', value: refreshToken);
  }

  @override
  Future<void> logout() async {
    await secureStorage.delete(key: 'jwt_token');
    await secureStorage.delete(key: 'refresh_token');
  }

  @override
  Future<String> login(String email, String password) async {
    await signInWithEmailAndPassword(email, password);
    return await getToken() ?? '';
  }
}
