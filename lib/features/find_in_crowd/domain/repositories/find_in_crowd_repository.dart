import '../../presentation/models/finder_location_ui_model.dart';
import '../entities/finder_models.dart';

abstract class FindInCrowdRepository {
  Future<List<EventFinderMember>> getEventMembers(String eventId);
  Future<FinderSession?> getActiveSession(String eventId);
  Future<FinderRequest> getRequest(String requestId);
  Future<FinderSession> getSession(String sessionId);
  Future<FinderRequest> createRequest({
    required String eventId,
    required String receiverId,
    required FinderLocationUiModel initialLocation,
  });
  Future<FinderSession?> respondRequest({
    required String requestId,
    required bool accept,
    FinderLocationUiModel? initialLocation,
  });
  Future<void> cancelRequest(String requestId);
  Future<void> sendLocation({
    required String sessionId,
    required FinderLocationUiModel location,
  });
  Future<void> stopSession(String sessionId);
}
