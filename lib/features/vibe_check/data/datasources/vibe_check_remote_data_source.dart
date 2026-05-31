import '../../../../core/network/dio_client.dart';
import '../models/vibe_check_response_dto.dart';

class VibeCheckRemoteDataSource {
  VibeCheckRemoteDataSource(this._dio);

  final DioClient _dio;

  Future<VibeCheckResponseDTO> checkVibe(String targetUserId) async {
    final response = await _dio.post(
      '/api/vibe-check',
      data: {'targetUserId': targetUserId},
    );
    return VibeCheckResponseDTO.fromJson(response.data);
  }
}
