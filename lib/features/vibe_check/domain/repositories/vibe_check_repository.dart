import '../entities/vibe_check_result.dart';

abstract class VibeCheckRepository {
  Future<VibeCheckResult> checkVibe(String targetUserId);
}
