import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/auth_user.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dio);

  final Dio _dio;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  @override
  Future<AuthUser> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final endpoint = ApiEndpoints.login;
    final _ = _dio.options.baseUrl + endpoint;
    await Future.delayed(const Duration(seconds: 1));

    // Uncomment for real API:
    // final response = await _dio.post(
    //   ApiEndpoints.login,
    //   data: {'email': email, 'password': password},
    // );
    // final token = response.data['accessToken'] as String;
    // final refreshToken = response.data['refreshToken'] as String;
    // await saveToken(token, refreshToken);
    // final userJson = response.data['user'] as Map<String, dynamic>;
    // return AuthUser(
    //   id: userJson['id'] as String,
    //   email: userJson['email'] as String,
    //   displayName: userJson['displayName'] as String,
    // );

    if (email == 'test@example.com' && password == 'password123') {
      const user = AuthUser(
        id: '1',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      await saveToken('mock_jwt_token_12345', 'mock_refresh_token');
      return user;
    }
    throw Exception('Invalid credentials');
  }

  @override
  Future<AuthUser> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    final endpoint = ApiEndpoints.register;
    final _ = _dio.options.baseUrl + endpoint;
    await Future.delayed(const Duration(seconds: 1));

    // Uncomment for real API:
    // final response = await _dio.post(
    //   ApiEndpoints.register,
    //   data: {
    //     'email': email,
    //     'password': password,
    //     'displayName': displayName,
    //   },
    // );
    // await saveToken(
    //   response.data['accessToken'] as String,
    //   response.data['refreshToken'] as String,
    // );
    // final userJson = response.data['user'] as Map<String, dynamic>;
    // return AuthUser(
    //   id: userJson['id'] as String,
    //   email: userJson['email'] as String,
    //   displayName: userJson['displayName'] as String,
    // );

    final user = AuthUser(id: '2', email: email, displayName: displayName);
    await saveToken('mock_jwt_token_67890', 'mock_refresh_token');
    return user;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await logout();
  }

  @override
  Future<AuthUser?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final token = await getToken();
    if (token != null) {
      return const AuthUser(
        id: '1',
        email: 'test@example.com',
        displayName: 'Test User',
      );
    }
    return null;
  }

  @override
  Future<String?> getToken() async {
    return await secureStorage.read(key: 'jwt_token');
  }

  @override
  Future<void> logout() async {
    await secureStorage.delete(key: 'jwt_token');
    await secureStorage.delete(key: 'refresh_token');
  }

  @override
  Future<void> saveToken(String token, String refreshToken) async {
    await secureStorage.write(key: 'jwt_token', value: token);
    await secureStorage.write(key: 'refresh_token', value: refreshToken);
  }

  @override
  Future<String> login(String email, String password) async {
    await signInWithEmailAndPassword(email, password);
    final token = await getToken();
    return token ?? '';
  }
}
