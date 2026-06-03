import 'package:dio/dio.dart';

import '../../domain/entities/finder_models.dart';
import '../../presentation/models/finder_location_ui_model.dart';

class FindInCrowdApiService {
  FindInCrowdApiService(this._dio);

  final Dio _dio;

  dynamic _unwrap(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('data')) return responseData['data'];
      if (responseData.containsKey('Data')) return responseData['Data'];
    }
    return responseData;
  }

  Future<List<EventFinderMember>> getEventMembers(String eventId) async {
    final response = await _dio.get('/api/app/matches/$eventId/finder/members');
    final unwrapped = _unwrap(response.data);
    final list = unwrapped is Map
        ? (unwrapped['members'] ?? unwrapped['Members']) as List? ?? []
        : (unwrapped is List ? unwrapped : []);
    return list
        .map((item) => EventFinderMember.fromJson(_asMap(item)))
        .toList();
  }

  Future<FinderSession?> getActiveSession(String eventId) async {
    final response = await _dio.get(
      '/api/app/matches/$eventId/finder/active-session',
    );
    final unwrapped = _unwrap(response.data);
    if (unwrapped == null) return null;
    if (unwrapped is Map &&
        (unwrapped['session'] == null || unwrapped['Session'] == null) &&
        !unwrapped.containsKey('sessionId') &&
        !unwrapped.containsKey('SessionId')) {
      return null;
    }
    return FinderSession.fromJson(_asMap(unwrapped));
  }

  Future<FinderRequest> getRequest(String requestId) async {
    final response = await _dio.get('/api/app/finder/requests/$requestId');
    return FinderRequest.fromJson(_asMap(_unwrap(response.data)));
  }

  Future<FinderSession> getSession(String sessionId) async {
    final response = await _dio.get('/api/app/finder/sessions/$sessionId');
    return FinderSession.fromJson(_asMap(_unwrap(response.data)));
  }

  Future<FinderRequest> createRequest({
    required String eventId,
    required String receiverId,
    required FinderLocationUiModel initialLocation,
  }) async {
    final response = await _dio.post(
      '/api/app/matches/$eventId/finder/requests',
      data: {
        'receiverId': receiverId,
        'initialLocation': locationToJson(initialLocation),
      },
    );
    return FinderRequest.fromJson(_asMap(_unwrap(response.data)));
  }

  Future<FinderSession?> respondRequest({
    required String requestId,
    required bool accept,
    FinderLocationUiModel? initialLocation,
  }) async {
    final response = await _dio.post(
      '/api/app/finder/requests/$requestId/respond',
      data: {
        'action': accept ? 'accept' : 'decline',
        if (initialLocation != null)
          'initialLocation': locationToJson(initialLocation),
      },
    );
    if (!accept) return null;
    return FinderSession.fromJson(_asMap(_unwrap(response.data)));
  }

  Future<void> cancelRequest(String requestId) async {
    await _dio.post('/api/app/finder/requests/$requestId/cancel');
  }

  Future<void> sendLocation({
    required String sessionId,
    required FinderLocationUiModel location,
  }) async {
    await _dio.post(
      '/api/app/finder/sessions/$sessionId/location',
      data: locationToJson(location),
    );
  }

  Future<void> stopSession(String sessionId) async {
    await _dio.post('/api/app/finder/sessions/$sessionId/stop');
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }
}
