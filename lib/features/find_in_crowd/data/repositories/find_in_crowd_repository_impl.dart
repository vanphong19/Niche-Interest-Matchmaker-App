import '../../domain/entities/finder_models.dart';
import '../../domain/repositories/find_in_crowd_repository.dart';
import '../../presentation/models/finder_location_ui_model.dart';
import '../services/find_in_crowd_api_service.dart';

class FindInCrowdRepositoryImpl implements FindInCrowdRepository {
  FindInCrowdRepositoryImpl(this._apiService);

  final FindInCrowdApiService _apiService;

  @override
  Future<List<EventFinderMember>> getEventMembers(String eventId) {
    return _apiService.getEventMembers(eventId);
  }

  @override
  Future<FinderSession?> getActiveSession(String eventId) {
    return _apiService.getActiveSession(eventId);
  }

  @override
  Future<FinderRequest> getRequest(String requestId) {
    return _apiService.getRequest(requestId);
  }

  @override
  Future<FinderSession> getSession(String sessionId) {
    return _apiService.getSession(sessionId);
  }

  @override
  Future<FinderRequest> createRequest({
    required String eventId,
    required String receiverId,
    required FinderLocationUiModel initialLocation,
  }) {
    return _apiService.createRequest(
      eventId: eventId,
      receiverId: receiverId,
      initialLocation: initialLocation,
    );
  }

  @override
  Future<FinderSession?> respondRequest({
    required String requestId,
    required bool accept,
    FinderLocationUiModel? initialLocation,
  }) {
    return _apiService.respondRequest(
      requestId: requestId,
      accept: accept,
      initialLocation: initialLocation,
    );
  }

  @override
  Future<void> cancelRequest(String requestId) {
    return _apiService.cancelRequest(requestId);
  }

  @override
  Future<void> sendLocation({
    required String sessionId,
    required FinderLocationUiModel location,
  }) {
    return _apiService.sendLocation(sessionId: sessionId, location: location);
  }

  @override
  Future<void> stopSession(String sessionId) {
    return _apiService.stopSession(sessionId);
  }
}
