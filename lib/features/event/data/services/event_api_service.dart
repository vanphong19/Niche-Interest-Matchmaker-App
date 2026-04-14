// lib/features/event/data/services/event_api_service.dart
import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/event.dart';

class EventApiService {
  EventApiService(this._dio);

  final Dio _dio;
  final Map<String, int> _selectionBoost = <String, int>{};

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
      'dateTime': DateTime.now()
          .add(const Duration(hours: 4))
          .toIso8601String(),
      'maxParticipants': 20,
      'currentParticipants': 12,
      'vibeTags': 'Active, Social',
      'isEliteOnly': true,
      'matchScore': 98.0,
      'image':
          'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?auto=format&fit=crop&w=400&q=80',
      'price': 0.0,
      'description':
          'Join us for a late-night padel session followed by fresh smoothies. All skill levels welcome!',
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
      'image':
          'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=400&q=80',
      'price': 5.0,
      'description':
          'Exploring the best hidden cafes in Thao Dien. We will visit 3 locations.',
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
      'dateTime': DateTime.now()
          .add(const Duration(hours: 2))
          .toIso8601String(),
      'maxParticipants': 15,
      'currentParticipants': 8,
      'vibeTags': 'Wellness, Quiet',
      'isEliteOnly': false,
      'matchScore': 75.0,
      'image':
          'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&w=400&q=80',
      'price': 0.0,
      'description':
          'Vinyasa flow ending with a guided meditation by the lake.',
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
      'image':
          'https://images.unsplash.com/photo-1515169067868-5387ec356754?auto=format&fit=crop&w=400&q=80',
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
      'image':
          'https://images.unsplash.com/photo-1551632811-561732d1e306?auto=format&fit=crop&w=400&q=80',
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
      'dateTime': DateTime.now()
          .add(const Duration(hours: 5))
          .toIso8601String(),
      'maxParticipants': 8,
      'currentParticipants': 6,
      'vibeTags': 'Casual',
      'isEliteOnly': false,
      'matchScore': 88.0,
      'image':
          'https://images.unsplash.com/photo-1610890716171-460d3d0fca7f?auto=format&fit=crop&w=400&q=80',
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
    if (category != null &&
        category.isNotEmpty &&
        category.toLowerCase() != 'all') {
      results = results
          .where(
            (e) =>
                e['category'].toString().toLowerCase() ==
                category.toLowerCase(),
          )
          .toList();
    }
    return results.map((e) => Event.fromJson(e)).toList();
  }

  Future<Event> getEventDetail(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final eventMap = _mockDb.firstWhere(
      (e) => e['id'] == id,
      orElse: () => _mockDb.first,
    );
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
      _mockDb[idx]['currentParticipants'] =
          (_mockDb[idx]['currentParticipants'] as int) + 1;
      return Event.fromJson(_mockDb[idx]);
    }
    throw Exception('Event not found');
  }

  Future<Event> leaveEvent(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final idx = _mockDb.indexWhere((e) => e['id'] == id);
    if (idx != -1) {
      _mockDb[idx]['isJoined'] = false;
      _mockDb[idx]['currentParticipants'] =
          (_mockDb[idx]['currentParticipants'] as int) - 1;
      return Event.fromJson(_mockDb[idx]);
    }
    throw Exception('Event not found');
  }

  Future<void> createEvent(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final now = DateTime.now();
    final locationLat = (data['latitude'] as num?)?.toDouble() ?? 10.7769;
    final locationLng = (data['longitude'] as num?)?.toDouble() ?? 106.7009;
    final photos = ((data['photoUrls'] as List?) ?? const <dynamic>[])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
    final participantIds =
        ((data['participantIds'] as List?) ?? const <dynamic>[])
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList();

    final newEvent = {
      'id': (data['id']?.toString().isNotEmpty ?? false)
          ? data['id'].toString()
          : 'evt-${now.millisecondsSinceEpoch}',
      'title': data['title']?.toString() ?? 'Untitled Event',
      'description':
          data['description']?.toString() ?? 'A new vibe created by you!',
      'category': data['category']?.toString() ?? 'social',
      'hostId': data['hostId']?.toString() ?? 'current-user',
      'hostName': data['hostName']?.toString() ?? 'Current User',
      'hostAvatar':
          data['hostAvatar']?.toString() ?? 'https://i.pravatar.cc/100?img=11',
      'lat': locationLat,
      'lng': locationLng,
      'location': {
        'name': data['locationName'] ?? 'Custom Location',
        'address': data['location'] ?? 'Vietnam',
        'latitude': locationLat,
        'longitude': locationLng,
        'placeId': data['placeId'],
      },
      'dateTime':
          data['startDateTime']?.toString() ??
          data['date']?.toIso8601String() ??
          now.toIso8601String(),
      'endTime': data['endDateTime']?.toString(),
      'maxParticipants': data['maxParticipants'] ?? data['participants'] ?? 10,
      'currentParticipants': data['currentParticipants'] ?? 1,
      'participantIds': participantIds,
      'vibeTags': data['vibeTags']?.toString() ?? 'New Event',
      'isEliteOnly': data['isEliteOnly'] ?? false,
      'matchScore': (data['matchScore'] as num?)?.toDouble() ?? 90.0,
      'images': photos,
      'image': photos.isNotEmpty
          ? photos.first
          : 'https://images.unsplash.com/photo-1454496522488-7a8e488e8606?auto=format&fit=crop&w=400&q=80',
      'price': 0.0,
      'participants': [
        {'avatarUrl': 'https://i.pravatar.cc/100?img=11'},
      ],
      'status': data['status']?.toString() ?? 'active',
      'isJoined': data['isJoined'] ?? true,
      'createdAt': data['createdAt']?.toString() ?? now.toIso8601String(),
    };
    _mockDb.insert(0, newEvent);
  }

  Future<Map<String, List<Event>>> getMyEvents() async {
    await Future.delayed(const Duration(milliseconds: 600));
    final hosting = _mockDb
        .where(
          (e) =>
              e['hostName'] == 'Marcus Chen' || e['hostName'] == 'Current User',
        )
        .map((e) => Event.fromJson(e))
        .toList();
    final joined = _mockDb
        .where((e) => e['isJoined'] == true)
        .map((e) => Event.fromJson(e))
        .toList();
    final past = _mockDb
        .map((e) {
          final evt = Map<String, dynamic>.from(e);
          evt['status'] = 'completed';
          return Event.fromJson(evt);
        })
        .take(2)
        .toList();
    return {'hosting': hosting, 'joined': joined, 'past': past};
  }

  static const List<Map<String, dynamic>> _vnLandmarks = [
    {
      'name': 'Đại học Quốc gia TP.HCM',
      'address': 'Khu đô thị ĐHQG, TP. Thủ Đức, TP.HCM',
      'lat': 10.8797,
      'lng': 106.8038,
      'aliases': ['VNU-HCM', 'DHQG', 'ĐHQG TP.HCM'],
    },
    {
      'name': 'Đại học Công nghệ Thông tin - ĐHQG TP.HCM',
      'address': 'Khu phố 6, Linh Trung, TP. Thủ Đức, TP.HCM',
      'lat': 10.8701,
      'lng': 106.8032,
      'aliases': ['UIT', 'UIT HCM', 'UIT TPHCM', 'ĐH CNTT'],
    },
    {
      'name': 'Đại học Bách Khoa TP.HCM',
      'address': '268 Lý Thường Kiệt, Quận 10, TP.HCM',
      'lat': 10.7733,
      'lng': 106.6587,
      'aliases': ['HCMUT', 'Bach Khoa', 'ĐH Bách Khoa'],
    },
    {
      'name': 'Đại học Kinh tế Quốc dân',
      'address': '207 Giải Phóng, Hai Bà Trưng, Hà Nội',
      'lat': 21.0041,
      'lng': 105.8433,
      'aliases': ['NEU'],
    },
    {
      'name': 'Đại học Quốc gia Hà Nội',
      'address': '144 Xuân Thủy, Cầu Giấy, Hà Nội',
      'lat': 21.0368,
      'lng': 105.7831,
      'aliases': ['VNU Hanoi', 'ĐHQGHN'],
    },
    {
      'name': 'Đại học Đà Nẵng',
      'address': '41 Lê Duẩn, Hải Châu, Đà Nẵng',
      'lat': 16.0723,
      'lng': 108.2216,
      'aliases': ['UDN'],
    },
    {
      'name': 'Sân bay Tân Sơn Nhất',
      'address': 'Trường Sơn, Tân Bình, TP.HCM',
      'lat': 10.8188,
      'lng': 106.6519,
    },
    {
      'name': 'Sân bay Nội Bài',
      'address': 'Phú Minh, Sóc Sơn, Hà Nội',
      'lat': 21.2187,
      'lng': 105.8042,
    },
    {
      'name': 'Landmark 81',
      'address': 'Vinhomes Central Park, Bình Thạnh, TP.HCM',
      'lat': 10.7949,
      'lng': 106.7219,
      'aliases': ['Vincom Landmark 81'],
    },
    {
      'name': 'Bitexco Financial Tower',
      'address': '2 Hải Triều, Quận 1, TP.HCM',
      'lat': 10.7717,
      'lng': 106.7044,
    },
    {
      'name': 'Hồ Hoàn Kiếm',
      'address': 'Hoàn Kiếm, Hà Nội',
      'lat': 21.0288,
      'lng': 105.8522,
      'aliases': ['Hồ Gươm'],
    },
    {
      'name': 'Bến Nhà Rồng',
      'address': '1 Nguyễn Tất Thành, Quận 4, TP.HCM',
      'lat': 10.7696,
      'lng': 106.7056,
    },
    {
      'name': 'Bãi biển Mỹ Khê',
      'address': 'Sơn Trà, Đà Nẵng',
      'lat': 16.0597,
      'lng': 108.2469,
    },
  ];

  String _normalizeVietnamese(String text) {
    var value = text.toLowerCase().trim();
    const replacements = {
      'a': 'àáạảãâầấậẩẫăằắặẳẵ',
      'e': 'èéẹẻẽêềếệểễ',
      'i': 'ìíịỉĩ',
      'o': 'òóọỏõôồốộổỗơờớợởỡ',
      'u': 'ùúụủũưừứựửữ',
      'y': 'ỳýỵỷỹ',
      'd': 'đ',
    };
    replacements.forEach((ascii, unicodeSet) {
      value = value.replaceAll(RegExp('[$unicodeSet]'), ascii);
    });
    return value;
  }

  List<String> _tokenize(String text) {
    return _normalizeVietnamese(
      text,
    ).split(RegExp(r'[^a-z0-9]+')).where((token) => token.length >= 2).toList();
  }

  int _scoreLandmark(String query, Map<String, dynamic> place) {
    final normalizedQuery = _normalizeVietnamese(query);
    final name = _normalizeVietnamese(place['name'].toString());
    final address = _normalizeVietnamese(place['address'].toString());
    final aliases = ((place['aliases'] as List?) ?? const <dynamic>[])
        .map((e) => _normalizeVietnamese(e.toString()))
        .join(' ');
    final corpus = '$name $address $aliases';

    var score = 0;
    if (name.contains(normalizedQuery)) score += 36;
    if (aliases.contains(normalizedQuery)) score += 30;
    if (address.contains(normalizedQuery)) score += 14;

    for (final token in _tokenize(query)) {
      if (name.contains(token)) score += 12;
      if (aliases.contains(token)) score += 11;
      if (address.contains(token)) score += 5;
      if (corpus.contains(token)) score += 1;
    }

    return score;
  }

  List<Map<String, dynamic>> _searchVietnamLandmarks(String query) {
    final ranked =
        _vnLandmarks
            .map((place) => (place, _scoreLandmark(query, place)))
            .where((entry) => entry.$2 > 0)
            .toList()
          ..sort((a, b) => b.$2.compareTo(a.$2));

    return ranked.map((entry) {
      final place = Map<String, dynamic>.from(entry.$1);
      place.remove('aliases');
      return place;
    }).toList();
  }

  List<Map<String, dynamic>> _mergePlaceResults(
    List<Map<String, dynamic>> primary,
    List<Map<String, dynamic>> secondary,
  ) {
    final merged = <Map<String, dynamic>>[];
    final seen = <String>{};

    void addAll(List<Map<String, dynamic>> source) {
      for (final place in source) {
        final key = '${place['name']}-${place['lat']}-${place['lng']}';
        if (seen.add(key)) {
          merged.add(place);
        }
      }
    }

    addAll(primary);
    addAll(secondary);

    merged.sort((a, b) {
      final aKey = _normalizeVietnamese(a['name']?.toString() ?? '');
      final bKey = _normalizeVietnamese(b['name']?.toString() ?? '');
      final aScore = _selectionBoost[aKey] ?? 0;
      final bScore = _selectionBoost[bKey] ?? 0;
      return bScore.compareTo(aScore);
    });

    return merged.take(10).toList();
  }

  void recordPlaceSelection(Map<String, dynamic> place) {
    final key = _normalizeVietnamese(place['name']?.toString() ?? '');
    if (key.isEmpty) {
      return;
    }
    _selectionBoost[key] = (_selectionBoost[key] ?? 0) + 1;
  }

  Future<List<Map<String, dynamic>>> _queryNominatim(
    String query, {
    String? countryCodes,
    int limit = 8,
  }) async {
    final response = await _dio.get(
      'https://nominatim.openstreetmap.org/search',
      queryParameters: {
        'q': query,
        'format': 'jsonv2',
        'addressdetails': 1,
        'dedupe': 1,
        'limit': limit,
        'countrycodes': ?countryCodes,
      },
      options: Options(
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'User-Agent': 'VibePulseApp/1.0 (production-search)'},
      ),
    );

    if (response.statusCode != 200 || response.data is! List) {
      return const [];
    }

    final data = response.data as List;
    return data.map((json) {
      return {
        'name':
            json['name'] ?? json['display_name']?.split(',').first ?? 'Unknown',
        'address': json['display_name'] ?? 'Unknown Address',
        'lat': double.tryParse(json['lat'].toString()) ?? 0.0,
        'lng': double.tryParse(json['lon'].toString()) ?? 0.0,
        'placeId': json['osm_id']?.toString(),
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (query.trim().length < 2) return [];

    final trimmedQuery = query.trim();
    final localResults = _searchVietnamLandmarks(trimmedQuery);
    final remoteResults = <Map<String, dynamic>>[];

    try {
      remoteResults.addAll(
        await _queryNominatim(
          '$trimmedQuery, Vietnam',
          countryCodes: 'vn',
          limit: 8,
        ),
      );

      if (remoteResults.length < 5) {
        remoteResults.addAll(
          await _queryNominatim(
            '$trimmedQuery Ho Chi Minh City',
            countryCodes: 'vn',
            limit: 6,
          ),
        );
      }

      if (remoteResults.length < 5) {
        remoteResults.addAll(await _queryNominatim(trimmedQuery, limit: 6));
      }
    } catch (e) {
      // Fallback to local Vietnam landmarks when network/geocoder fails.
    }

    return _mergePlaceResults(localResults, remoteResults);
  }
}
