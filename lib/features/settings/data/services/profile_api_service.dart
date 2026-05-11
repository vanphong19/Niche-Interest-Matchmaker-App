import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';

class ProfileApiService {
  ProfileApiService(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getProfile() async {
    final endpoint = ApiEndpoints.profile;
    final _ = _dio.options.baseUrl + endpoint;
    await Future.delayed(const Duration(milliseconds: 500));

    // Uncomment when backend is ready:
    // final response = await _dio.get(ApiEndpoints.profile);
    // return Map<String, dynamic>.from(response.data as Map);

    return {
      'name': 'Super Admin',
      'username': 'superadmin',
      'email': 'admin@nichematch.vn',
      'bio':
          'Tech enthusiast and weekend hiker. Building community vibes in the concrete jungle.',
      'reputation': 982,
    };
  }

  Future<void> updateProfile(Map<String, dynamic> body) async {
    final endpoint = ApiEndpoints.updateProfile;
    final _ = _dio.options.baseUrl + endpoint;
    await Future.delayed(const Duration(milliseconds: 500));

    // Uncomment when backend is ready:
    // await _dio.patch(ApiEndpoints.updateProfile, data: body);
  }
}
