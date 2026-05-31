import '../../domain/entities/vibe_check_result.dart';
import '../../domain/repositories/vibe_check_repository.dart';
import '../datasources/vibe_check_remote_data_source.dart';

class VibeCheckRepositoryImpl implements VibeCheckRepository {
  VibeCheckRepositoryImpl(this._remoteDataSource);

  final VibeCheckRemoteDataSource _remoteDataSource;

  @override
  Future<VibeCheckResult> checkVibe(String targetUserId) async {
    final dto = await _remoteDataSource.checkVibe(targetUserId);
    final entity = dto.toEntity();
    if (entity == null) {
      throw Exception(dto.error ?? 'Vibe check failed');
    }
    return entity;
  }
}
