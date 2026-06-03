import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
    int? limit,
    int? offset,
  }) async {
    final response = await _dio.get(
      '/api/app/matches',
      queryParameters: {
        'category': category,
        'lat': lat,
        'lng': lng,
        'limit': limit,
        'offset': offset,
      }..removeWhere((_, v) => v == null),
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

  Future<Event> updateEvent(String eventId, Map<String, dynamic> data) async {
    final response = await _dio.put('/api/app/matches/$eventId', data: data);
    return Event.fromJson(_unwrap(response.data) as Map<String, dynamic>);
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
      'hosting':
          ((data['hosted'] ?? data['Hosted'] ?? data['hosting']) as List? ?? [])
              .map((e) => Event.fromJson(e as Map<String, dynamic>))
              .toList(),
      'joined':
          ((data['joining'] ?? data['Joining'] ?? data['joined']) as List? ??
                  [])
              .map((e) => Event.fromJson(e as Map<String, dynamic>))
              .toList(),
      'past': (data['past'] as List? ?? [])
          .map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList(),
    };
  }

  Future<Map<String, dynamic>> getMyEventsPaginated({
    required String tab,
    String? search,
    required int limit,
    required int offset,
  }) async {
    final response = await _dio.get(
      '/api/app/matches/my-events',
      queryParameters: {
        'tab': tab,
        if (search != null && search.isNotEmpty) 'search': search,
        'limit': limit,
        'offset': offset,
      },
    );
    final unwrapped = _unwrap(response.data);
    final data = unwrapped is Map<String, dynamic>
        ? unwrapped
        : <String, dynamic>{};

    final itemsList = data['items'] as List? ?? [];
    final items = itemsList
        .map((e) => Event.fromJson(e as Map<String, dynamic>))
        .toList();
    final totalCount = data['totalCount'] as int? ?? 0;

    return {'items': items, 'totalCount': totalCount};
  }

  String buildJoinRequestLink(String eventId) {
    try {
      final uri = Uri.base;
      // If running on Web, use the current web origin
      if (uri.scheme.startsWith('http')) {
        return '${uri.origin}/#/event/$eventId';
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

  Future<List<Map<String, String>>> searchUsers(
    String query, {
    String? eventId,
  }) async {
    try {
      final response = await _dio.get(
        '/api/app/profile/search',
        queryParameters: {
          'query': query,
          if (eventId != null && eventId.isNotEmpty) 'eventId': eventId,
        },
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
              'friendshipStatus':
                  (e['friendshipStatus'] ?? e['FriendshipStatus'] ?? 'None')
                      .toString(),
              'inviteStatus':
                  (e['inviteStatus'] ??
                          e['InviteStatus'] ??
                          e['eventStatus'] ??
                          e['EventStatus'] ??
                          'None')
                      .toString(),
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Search Users Error: $e');
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
              'friendshipStatus':
                  (e['friendshipStatus'] ?? e['FriendshipStatus'] ?? 'None')
                      .toString(),
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

  Future<Map<String, dynamic>?> reverseGeocodePlace({
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'jsonv2',
          'lat': lat,
          'lon': lng,
          'zoom': 18,
          'addressdetails': 1,
        },
        options: Options(
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'VibePulse/1.0 location picker',
          },
        ),
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) return null;

      final address = data['address'] is Map<String, dynamic>
          ? data['address'] as Map<String, dynamic>
          : <String, dynamic>{};
      final name =
          data['name']?.toString() ??
          address['amenity']?.toString() ??
          address['shop']?.toString() ??
          address['tourism']?.toString() ??
          address['building']?.toString() ??
          address['road']?.toString() ??
          address['suburb']?.toString() ??
          'Pinned location';
      final displayName = data['display_name']?.toString() ?? '';

      return {
        'name': name,
        'address': displayName.isNotEmpty ? displayName : name,
        'placeId': data['place_id']?.toString(),
        'lat': lat,
        'lng': lng,
      };
    } catch (e) {
      debugPrint('Reverse Geocode Error: $e');
      return null;
    }
  }

  Future<String?> uploadImage(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post(
        '/api/app/matches/upload-image',
        data: formData,
      );

      final unwrapped = _unwrap(response.data);
      if (unwrapped is Map<String, dynamic>) {
        return unwrapped['url']?.toString() ?? unwrapped['Url']?.toString();
      }
      return null;
    } catch (e) {
      debugPrint('Upload Image Error: $e');
      return null;
    }
  }

  Future<String?> uploadImageBytes(Uint8List bytes, String fileName) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });

      final response = await _dio.post(
        '/api/app/matches/upload-image',
        data: formData,
      );

      final unwrapped = _unwrap(response.data);
      if (unwrapped is Map<String, dynamic>) {
        return unwrapped['url']?.toString() ?? unwrapped['Url']?.toString();
      }
      return null;
    } catch (e) {
      debugPrint('Upload Image Bytes Error: $e');
      return null;
    }
  }
}
