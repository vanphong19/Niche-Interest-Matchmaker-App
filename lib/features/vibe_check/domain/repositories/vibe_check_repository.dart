import '../entities/group_vibe_check_result.dart';
import '../entities/vibe_check_result.dart';

abstract class VibeCheckRepository {
  Future<VibeCheckResult> checkVibe(String targetUserId);

  Future<GroupVibeCheckResult> checkGroupVibe(
    String matchId, {
    int? maxMembers,
  });
}
