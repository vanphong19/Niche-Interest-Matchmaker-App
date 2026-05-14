import 'package:dio/dio.dart';
import '../../domain/entities/event.dart';

class EventApiService {
  EventApiService(this._dio);

  final Dio _dio;

  dynamic _unwrap(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('data')) return responseData['data'];
      if (responseData.containsKey('Data')) return responseData['Data'];
    }
    return responseData;
  }

  Future<List<Event>> getEvents({
    String? category,
    double? lat,
    double? lng,
  }) async {
    final response = await _dio.get(
      '/api/app/matches',
      queryParameters: {'category': category, 'lat': lat, 'lng': lng}
        ..removeWhere((_, v) => v == null),
    );
    final unwrapped = _unwrap(response.data);
    final data = unwrapped is List ? unwrapped : [];
    return data.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Event> getEventDetail(String id) async {
    final response = await _dio.get('/api/app/matches/$id');
    return Event.fromJson(_unwrap(response.data) as Map<String, dynamic>);
  }

  Future<List<Event>> getNearbyEvents({
    required double lat,
    required double lng,
  }) async {
    final response = await _dio.get(
      '/api/app/matches/nearby',
      queryParameters: {'lat': lat, 'lng': lng},
    );
    final unwrapped = _unwrap(response.data);
    final data = unwrapped is List ? unwrapped : [];
    return data.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Event> joinEvent(String id) async {
    final response = await _dio.post('/api/app/matches/$id/join');
    return Event.fromJson(_unwrap(response.data) as Map<String, dynamic>);
  }

  Future<Event> leaveEvent(String id) async {
    final response = await _dio.post('/api/app/matches/$id/leave');
    return Event.fromJson(_unwrap(response.data) as Map<String, dynamic>);
  }

  Future<void> createEvent(Map<String, dynamic> data) async {
    await _dio.post('/api/app/matches', data: data);
  }

  Future<void> pinEvent(String id) async {
    await _dio.post('/api/app/matches/$id/pin');
  }

  Future<void> unpinEvent(String id) async {
    await _dio.post('/api/app/matches/$id/unpin');
  }

  Future<Map<String, List<Event>>> getMyEvents() async {
    final response = await _dio.get('/api/app/matches/my-events');
    final unwrapped = _unwrap(response.data);
    final data = unwrapped is Map<String, dynamic>
        ? unwrapped
        : <String, dynamic>{};

    return {
      'hosting': (data['hosting'] as List? ?? [])
          .map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList(),
      'joined': (data['joined'] as List? ?? [])
          .map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList(),
      'past': (data['past'] as List? ?? [])
          .map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList(),
    };
  }

  String buildJoinRequestLink(String eventId) {
    try {
      final uri = Uri.base;
      // If running on Web, use the current web origin
      if (uri.scheme.startsWith('http')) {
        return '${uri.origin}/event/$eventId';
      }
    } catch (_) {}

    // For Android/Mobile testing, custom scheme is more reliable without hosting .well-known files
    return 'vibepulse://event/$eventId';
  }

  Future<void> approveJoinRequest(String eventId, String requestId) async {
    await _dio.post('/api/app/matches/$eventId/approve/$requestId');
  }

  Future<void> rejectJoinRequest(String eventId, String requestId) async {
    await _dio.post('/api/app/matches/$eventId/reject/$requestId');
  }

  Future<void> removeParticipant(String eventId, String userId) async {
    await _dio.delete('/api/app/matches/$eventId/participants/$userId');
  }

  Future<void> deleteEvent(String eventId) async {
    await _dio.delete('/api/app/matches/$eventId');
  }

  Future<void> inviteUser(String eventId, String userId) async {
    await _dio.post('/api/app/matches/$eventId/invite/$userId');
  }

  Future<List<Map<String, String>>> searchUsers(String query) async {
    try {
      final response = await _dio.get(
        '/api/app/profile/search',
        queryParameters: {'query': query},
      );
      final unwrapped = _unwrap(response.data);
      final data = unwrapped is List ? unwrapped : [];
      return data
          .map(
            (e) => {
              'id': (e['id'] ?? e['Id'] ?? '').toString(),
              'name': (e['name'] ?? e['Name'] ?? '').toString(),
              'avatarUrl': (e['avatarUrl'] ?? e['AvatarUrl'] ?? '').toString(),
              'email': (e['email'] ?? e['Email'] ?? '').toString(),
            },
          )
          .toList();
    } catch (e) {
      print('Search Users Error: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> getEventParticipants(String eventId) async {
    try {
      final response = await _dio.get('/api/app/matches/$eventId/participants');
      final unwrapped = _unwrap(response.data);
      final data = unwrapped is List ? unwrapped : [];
      return data
          .map(
            (e) => {
              'id': (e['id'] ?? '').toString(),
              'name': (e['name'] ?? e['displayName'] ?? '').toString(),
              'avatarUrl': (e['avatarUrl'] ?? '').toString(),
              'role': (e['role'] ?? 'Participant').toString(),
            },
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, String>>> getPendingJoinRequests(
    String eventId,
  ) async {
    try {
      final response = await _dio.get('/api/app/matches/$eventId/requests');
      final unwrapped = _unwrap(response.data);
      final data = unwrapped is List ? unwrapped : [];
      return data
          .map(
            (e) => {
              'id': (e['id'] ?? '').toString(),
              'name': (e['name'] ?? '').toString(),
              'avatarUrl': (e['avatarUrl'] ?? '').toString(),
              'message': (e['message'] ?? 'Wants to join').toString(),
            },
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    // Allowing short or empty query to fetch default/top results

    final response = await _dio.get(
      '/api/app/places',
      queryParameters: {if (query.trim().isNotEmpty) 'query': query.trim()},
    );
    final unwrapped = _unwrap(response.data);
    final data = unwrapped is List ? unwrapped : [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> recordPlaceSelection(Map<String, dynamic> place) async {
    // Analytics or recent places cache could go here.
  }
}
