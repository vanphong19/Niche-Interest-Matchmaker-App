// lib/features/event/data/services/event_api_service.dart
import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/event.dart';

class EventApiService {
  EventApiService(this._dio);

  final Dio _dio;

  final List<Map<String, dynamic>> _mockDb = [
    {
      'id': 'evt-001',
      'title': 'Midnight Padel & Smoothies',
      'category': 'Sports',
      'hostName': 'Marcus Chen',
      'hostAvatar': 'https://i.pravatar.cc/100?img=11',
      'lat': 10.7769,
      'lng': 106.7009,
      'location': {
        'name': 'District 1 Center',
        'address': 'Ho Chi Minh City, Vietnam',
        'latitude': 10.7769,
        'longitude': 106.7009,
      },
      'dateTime': DateTime.now().add(const Duration(hours: 4)).toIso8601String(),
      'maxParticipants': 20,
      'currentParticipants': 12,
      'vibeTags': 'Active, Social',
      'isEliteOnly': true,
      'matchScore': 98.0,
      'image': 'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?auto=format&fit=crop&w=400&q=80',
      'price': 0.0,
      'description': 'Join us for a late-night padel session followed by fresh smoothies. All skill levels welcome!',
      'participants': [
        {'avatarUrl': 'https://i.pravatar.cc/100?img=1'},
        {'avatarUrl': 'https://i.pravatar.cc/100?img=2'},
        {'avatarUrl': 'https://i.pravatar.cc/100?img=3'},
      ],
      'status': 'active',
      'isJoined': false,
    },
    {
      'id': 'evt-002',
      'title': 'Artisan Coffee Crawl',
      'category': 'Dining',
      'hostName': 'Linh Nguyen',
      'hostAvatar': 'https://i.pravatar.cc/100?img=34',
      'lat': 10.7876,
      'lng': 106.7455,
      'location': {
        'name': 'District 2, Thao Dien',
        'address': 'Ho Chi Minh City, Vietnam',
        'latitude': 10.7876,
        'longitude': 106.7455,
      },
      'dateTime': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      'maxParticipants': 10,
      'currentParticipants': 4,
      'vibeTags': 'Chill, Coffee Fans',
      'isEliteOnly': false,
      'matchScore': 85.0,
      'image': 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=400&q=80',
      'price': 5.0,
      'description': 'Exploring the best hidden cafes in Thao Dien. We will visit 3 locations.',
      'participants': [
        {'avatarUrl': 'https://i.pravatar.cc/100?img=4'},
        {'avatarUrl': 'https://i.pravatar.cc/100?img=5'},
      ],
      'status': 'active',
      'isJoined': false,
    },
    {
      'id': 'evt-003',
      'title': 'Sunset Yoga & Meditation',
      'category': 'Social',
      'hostName': 'Sarah J.',
      'hostAvatar': 'https://i.pravatar.cc/100?img=50',
      'lat': 10.7339,
      'lng': 106.7135,
      'location': {
        'name': 'District 7 Crescent Lake',
        'address': 'Ho Chi Minh City, Vietnam',
        'latitude': 10.7339,
        'longitude': 106.7135,
      },
      'dateTime': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
      'maxParticipants': 15,
      'currentParticipants': 8,
      'vibeTags': 'Wellness, Quiet',
      'isEliteOnly': false,
      'matchScore': 75.0,
      'image': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&w=400&q=80',
      'price': 0.0,
      'description': 'Vinyasa flow ending with a guided meditation by the lake.',
      'participants': [
        {'avatarUrl': 'https://i.pravatar.cc/100?img=6'},
        {'avatarUrl': 'https://i.pravatar.cc/100?img=7'},
      ],
      'status': 'active',
      'isJoined': false,
    },
    {
      'id': 'evt-004',
      'title': 'Tech Startup Mixer',
      'category': 'Social',
      'hostName': 'David Tran',
      'hostAvatar': 'https://i.pravatar.cc/100?img=60',
      'lat': 10.7769,
      'lng': 106.7009,
      'location': {
        'name': 'D1 Co-working Space',
        'address': 'Ho Chi Minh City, Vietnam',
        'latitude': 10.7769,
        'longitude': 106.7009,
      },
      'dateTime': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
      'maxParticipants': 50,
      'currentParticipants': 28,
      'vibeTags': 'Networking',
      'isEliteOnly': true,
      'matchScore': 90.0,
      'image': 'https://images.unsplash.com/photo-1515169067868-5387ec356754?auto=format&fit=crop&w=400&q=80',
      'price': 10.0,
      'description': 'Connect with local founders and developers.',
      'participants': [
        {'avatarUrl': 'https://i.pravatar.cc/100?img=8'},
        {'avatarUrl': 'https://i.pravatar.cc/100?img=9'},
      ],
      'status': 'active',
      'isJoined': false,
    },
    {
      'id': 'evt-005',
      'title': 'Weekend Hike at Dinh Mountain',
      'category': 'Outdoors',
      'hostName': 'Alex',
      'hostAvatar': 'https://i.pravatar.cc/100?img=68',
      'lat': 10.512,
      'lng': 107.123,
      'location': {
        'name': 'Dinh Mountain',
        'address': 'Ba Ria, Vung Tau',
        'latitude': 10.512,
        'longitude': 107.123,
      },
      'dateTime': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
      'maxParticipants': 12,
      'currentParticipants': 5,
      'vibeTags': 'Active, Adventure',
      'isEliteOnly': false,
      'matchScore': 65.0,
      'image': 'https://images.unsplash.com/photo-1551632811-561732d1e306?auto=format&fit=crop&w=400&q=80',
      'price': 0.0,
      'description': 'Moderate hike, bring plenty of water.',
      'participants': [
        {'avatarUrl': 'https://i.pravatar.cc/100?img=12'},
      ],
      'status': 'active',
      'isJoined': false,
    },
    {
      'id': 'evt-006',
      'title': 'Board Game Night',
      'category': 'Gaming',
      'hostName': 'Minh',
      'hostAvatar': 'https://i.pravatar.cc/100?img=69',
      'lat': 10.793,
      'lng': 106.690,
      'location': {
        'name': 'Phu Nhuan Boardgames',
        'address': 'Ho Chi Minh City, Vietnam',
        'latitude': 10.793,
        'longitude': 106.690,
      },
      'dateTime': DateTime.now().add(const Duration(hours: 5)).toIso8601String(),
      'maxParticipants': 8,
      'currentParticipants': 6,
      'vibeTags': 'Casual',
      'isEliteOnly': false,
      'matchScore': 88.0,
      'image': 'https://images.unsplash.com/photo-1610890716171-460d3d0fca7f?auto=format&fit=crop&w=400&q=80',
      'price': 3.0,
      'description': 'Playing Catan and Ticket to Ride.',
      'participants': [
        {'avatarUrl': 'https://i.pravatar.cc/100?img=15'},
        {'avatarUrl': 'https://i.pravatar.cc/100?img=16'},
      ],
      'status': 'active',
      'isJoined': false,
    },
  ];

  Future<List<Event>> getEvents({
    String? category,
    double? lat,
    double? lng,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    var results = _mockDb;
    if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
      results = results.where((e) => e['category'].toString().toLowerCase() == category.toLowerCase()).toList();
    }
    return results.map((e) => Event.fromJson(e)).toList();
  }

  Future<Event> getEventDetail(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final eventMap = _mockDb.firstWhere((e) => e['id'] == id, orElse: () => _mockDb.first);
    return Event.fromJson(eventMap);
  }

  Future<List<Event>> getNearbyEvents({
    required double lat,
    required double lng,
  }) async {
    await Future.delayed(const Duration(milliseconds: 550));
    return _mockDb.map((e) => Event.fromJson(e)).toList();
  }

  Future<Event> joinEvent(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final idx = _mockDb.indexWhere((e) => e['id'] == id);
    if (idx != -1) {
      _mockDb[idx]['isJoined'] = true;
      _mockDb[idx]['currentParticipants'] = (_mockDb[idx]['currentParticipants'] as int) + 1;
      return Event.fromJson(_mockDb[idx]);
    }
    throw Exception('Event not found');
  }

  Future<Event> leaveEvent(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final idx = _mockDb.indexWhere((e) => e['id'] == id);
    if (idx != -1) {
      _mockDb[idx]['isJoined'] = false;
      _mockDb[idx]['currentParticipants'] = (_mockDb[idx]['currentParticipants'] as int) - 1;
      return Event.fromJson(_mockDb[idx]);
    }
    throw Exception('Event not found');
  }

  Future<void> createEvent(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final newEvent = {
        'id': 'evt-${DateTime.now().millisecondsSinceEpoch}',
        'title': data['title'],
        'category': data['category'],
        'hostName': 'Current User',
        'hostAvatar': 'https://i.pravatar.cc/100?img=11',
        'lat': 10.7769,
        'lng': 106.7009,
        'location': {
          'name': data['locationName'] ?? 'Custom Location',
          'address': data['location'] ?? 'Vietnam',
          'latitude': 10.7769,
          'longitude': 106.7009,
        },
        'dateTime': data['date']?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'maxParticipants': data['participants'] ?? 10,
        'currentParticipants': 1,
        'vibeTags': 'New Event',
        'isEliteOnly': data['isEliteOnly'] ?? false,
        'matchScore': 90.0,
        'image': 'https://images.unsplash.com/photo-1454496522488-7a8e488e8606?auto=format&fit=crop&w=400&q=80',
        'price': 0.0,
        'description': 'A new vibe created by you!',
        'participants': [
          {'avatarUrl': 'https://i.pravatar.cc/100?img=11'},
        ],
        'status': 'active',
        'isJoined': true,
    };
    _mockDb.insert(0, newEvent);
  }

  Future<Map<String, List<Event>>> getMyEvents() async {
    await Future.delayed(const Duration(milliseconds: 600));
    final hosting = _mockDb.where((e) => e['hostName'] == 'Marcus Chen' || e['hostName'] == 'Current User').map((e) => Event.fromJson(e)).toList();
    final joined = _mockDb.where((e) => e['isJoined'] == true).map((e) => Event.fromJson(e)).toList();
    final past = _mockDb.map((e) {
       final evt = Map<String, dynamic>.from(e);
       evt['status'] = 'completed';
       return Event.fromJson(evt);
    }).take(2).toList();
    return {
      'hosting': hosting,
      'joined': joined,
      'past': past,
    };
  }

  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (query.length < 2) return [];
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 5,
        },
        options: Options(
          headers: {
             'User-Agent': 'VibePulseApp/1.0',
          }
        )
      );

      if (response.statusCode == 200) {
        final data = response.data as List;
        return data.map((json) {
           return {
             'name': json['name'] ?? json['display_name']?.split(',').first ?? 'Unknown',
             'address': json['display_name'] ?? 'Unknown Address',
             'lat': double.tryParse(json['lat'].toString()) ?? 0.0,
             'lng': double.tryParse(json['lon'].toString()) ?? 0.0,
           };
        }).toList();
      }
    } catch (e) {
      // Fallback
    }
    return [];
  }
}
