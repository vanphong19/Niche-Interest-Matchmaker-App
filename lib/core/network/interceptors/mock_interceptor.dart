// lib/core/network/interceptors/mock_interceptor.dart
import 'dart:math';

import 'package:dio/dio.dart';

import '../../constants/api_constants.dart';

const bool kUseMock = true;
const bool kMockError = false;

class MockInterceptor extends Interceptor {
  final _random = Random();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!kUseMock) {
      return handler.next(options);
    }

    // Simulate network delay (300-800ms)
    final delay = 300 + _random.nextInt(500);
    await Future.delayed(Duration(milliseconds: delay));

    if (kMockError) {
      return handler.reject(
        DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 500,
            data: {'error': 'Mock server error'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );
    }

    final mockData = _getMockResponse(options.path, options.method);
    if (mockData != null) {
      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: mockData,
        ),
      );
    }

    handler.next(options);
  }

  dynamic _getMockResponse(String path, String method) {
    // Normalize path by removing base URL prefix if present
    final normalizedPath = path.replaceFirst(
      RegExp(r'^https?://[^/]+/api/v1'),
      '',
    );

    switch (normalizedPath) {
      // ─── Auth ───────────────────────────────────────────────────
      case ApiConstants.login:
        return {
          'accessToken': 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
          'refreshToken': 'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
          'user': _mockUser(),
        };

      case ApiConstants.register:
        return {
          'accessToken': 'mock_jwt_token_new_${DateTime.now().millisecondsSinceEpoch}',
          'refreshToken': 'mock_refresh_token_new_${DateTime.now().millisecondsSinceEpoch}',
          'user': _mockUser(id: 'new_user_1'),
        };

      case ApiConstants.forgotPassword:
        return {
          'message': 'Password reset email sent successfully.',
          'otpSent': true,
        };

      case ApiConstants.verifyOtp:
        return {
          'verified': true,
          'message': 'OTP verified successfully.',
        };

      case ApiConstants.refreshToken:
        return {
          'accessToken': 'mock_new_access_token_${DateTime.now().millisecondsSinceEpoch}',
          'refreshToken': 'mock_new_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
        };

      // ─── Profile ────────────────────────────────────────────────
      case ApiConstants.profile:
        if (method == 'GET') {
          return {'user': _mockUser()};
        }
        if (method == 'PUT' || method == 'PATCH') {
          return {
            'user': _mockUser(),
            'message': 'Profile updated successfully.',
          };
        }
        return null;

      // ─── Events ─────────────────────────────────────────────────
      case ApiConstants.events:
        if (method == 'GET') {
          return {
            'events': List.generate(10, (i) => _mockEvent(i)),
            'total': 42,
            'page': 1,
            'limit': 10,
          };
        }
        if (method == 'POST') {
          return {
            'event': _mockEvent(99),
            'message': 'Event created successfully.',
          };
        }
        return null;

      case ApiConstants.nearbyEvents:
        return {
          'events': List.generate(8, (i) => _mockEvent(i, nearby: true)),
          'total': 8,
        };

      case ApiConstants.trendingEvents:
        return {
          'events': List.generate(5, (i) => _mockEvent(i, trending: true)),
          'total': 5,
        };

      case ApiConstants.myEvents:
        return {
          'events': List.generate(3, (i) => _mockEvent(i)),
          'total': 3,
        };

      case ApiConstants.eventCategories:
        return {
          'categories': [
            {'id': '1', 'name': 'Sports', 'icon': 'sports', 'color': '#FF6B6B'},
            {'id': '2', 'name': 'Dining', 'icon': 'restaurant', 'color': '#FF9F43'},
            {'id': '3', 'name': 'Social', 'icon': 'groups', 'color': '#5B5FF8'},
            {'id': '4', 'name': 'Arts', 'icon': 'palette', 'color': '#A29BFE'},
            {'id': '5', 'name': 'Outdoors', 'icon': 'nature', 'color': '#00B894'},
            {'id': '6', 'name': 'Gaming', 'icon': 'sports_esports', 'color': '#FDCB6E'},
            {'id': '7', 'name': 'Music', 'icon': 'music_note', 'color': '#E84393'},
            {'id': '8', 'name': 'Tech', 'icon': 'computer', 'color': '#0984E3'},
          ],
        };

      // ─── Map ────────────────────────────────────────────────────
      case ApiConstants.mapMarkers:
        return {
          'markers': List.generate(15, (i) => _mockMapMarker(i)),
        };

      // ─── Notifications ──────────────────────────────────────────
      case ApiConstants.notifications:
        return {
          'notifications': List.generate(5, (i) => _mockNotification(i)),
          'unreadCount': 3,
        };

      // ─── Badges ─────────────────────────────────────────────────
      case ApiConstants.badges:
      case ApiConstants.myBadges:
        return {
          'badges': List.generate(6, (i) => _mockBadge(i)),
        };

      default:
        // Handle path with IDs, e.g. /events/123
        if (normalizedPath.startsWith('/events/') && method == 'GET') {
          return {'event': _mockEvent(1)};
        }
        if (normalizedPath.startsWith('/users/') && method == 'GET') {
          return {'user': _mockUser()};
        }
        if (normalizedPath.startsWith('/badges/') && method == 'GET') {
          return {'badge': _mockBadge(1)};
        }
        return null;
    }
  }

  // ─── Mock Data Generators ───────────────────────────────────────
  Map<String, dynamic> _mockUser({String id = 'user_1'}) {
    return {
      'id': id,
      'email': 'user@vibepulse.app',
      'displayName': 'Alex Nguyen',
      'username': 'alexnguyen',
      'bio': 'Passionate about connecting people through amazing experiences! 🎯',
      'avatarUrl': 'https://i.pravatar.cc/300?u=$id',
      'coverUrl': 'https://picsum.photos/800/300',
      'phoneNumber': '+84901234567',
      'location': {
        'lat': 10.8231,
        'lng': 106.6297,
        'address': 'Ho Chi Minh City, Vietnam',
      },
      'interests': ['Sports', 'Music', 'Tech', 'Gaming', 'Dining'],
      'stats': {
        'eventsCreated': 12,
        'eventsJoined': 34,
        'connections': 156,
        'badges': 8,
      },
      'badges': [
        {'id': 'badge_1', 'name': 'Early Adopter', 'icon': '🚀'},
        {'id': 'badge_2', 'name': 'Social Butterfly', 'icon': '🦋'},
      ],
      'verified': true,
      'createdAt': '2024-01-15T10:00:00Z',
      'lastActive': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _mockEvent(int index, {bool nearby = false, bool trending = false}) {
    final categories = ['Sports', 'Dining', 'Social', 'Arts', 'Outdoors', 'Gaming', 'Music', 'Tech'];
    final category = categories[index % categories.length];
    final titles = [
      'Weekend Football Match ⚽',
      'Rooftop BBQ Night 🍖',
      'Board Game Meetup 🎲',
      'Art Gallery Tour 🎨',
      'Sunrise Hike 🏔️',
      'E-Sports Tournament 🎮',
      'Live Jazz Evening 🎵',
      'AI Workshop 💻',
      'Beach Volleyball 🏐',
      'Wine & Cheese Night 🧀',
    ];

    return {
      'id': 'event_${index}_${DateTime.now().millisecondsSinceEpoch}',
      'title': titles[index % titles.length],
      'description':
          'Join us for an amazing $category event! This is a great opportunity to meet new people and have fun. Everyone is welcome regardless of skill level.',
      'category': category,
      'imageUrl': 'https://picsum.photos/400/250?random=$index',
      'images': List.generate(
        3,
        (i) => 'https://picsum.photos/400/250?random=${index * 10 + i}',
      ),
      'location': {
        'lat': 10.8231 + (index * 0.01) - 0.05,
        'lng': 106.6297 + (index * 0.01) - 0.05,
        'address': '${100 + index} Nguyen Hue, District 1',
        'placeName': 'Cool Venue ${index + 1}',
      },
      'dateTime': DateTime.now()
          .add(Duration(days: index + 1, hours: index * 2))
          .toIso8601String(),
      'endTime': DateTime.now()
          .add(Duration(days: index + 1, hours: index * 2 + 3))
          .toIso8601String(),
      'creator': _mockUser(id: 'creator_$index'),
      'participants': List.generate(
        3 + index % 5,
        (i) => _mockUser(id: 'participant_${index}_$i'),
      ),
      'maxParticipants': 10 + index * 2,
      'currentParticipants': 3 + index % 5,
      'matchScore': 65 + (index * 7) % 35,
      'isTrending': trending || index < 3,
      'isJoined': index % 3 == 0,
      'isFavorited': index % 4 == 0,
      'tags': ['fun', category.toLowerCase(), 'weekend'],
      'price': index % 2 == 0 ? 0 : (index * 50000),
      'currency': 'VND',
      'status': 'active',
      'createdAt': DateTime.now()
          .subtract(Duration(days: index))
          .toIso8601String(),
    };
  }

  Map<String, dynamic> _mockMapMarker(int index) {
    return {
      'id': 'marker_$index',
      'eventId': 'event_$index',
      'title': 'Event #${index + 1}',
      'category': ['Sports', 'Dining', 'Social', 'Arts', 'Outdoors'][index % 5],
      'lat': 10.8231 + (index * 0.008) - 0.04,
      'lng': 106.6297 + (index * 0.008) - 0.04,
      'participantCount': 3 + index,
      'maxParticipants': 10 + index * 2,
      'matchScore': 60 + (index * 8) % 40,
    };
  }

  Map<String, dynamic> _mockNotification(int index) {
    final types = ['event_invite', 'event_update', 'new_follower', 'badge_earned', 'event_reminder'];
    return {
      'id': 'notif_$index',
      'type': types[index % types.length],
      'title': 'Notification ${index + 1}',
      'body': 'This is a sample notification message for testing purposes.',
      'data': {'eventId': 'event_$index'},
      'read': index > 2,
      'createdAt': DateTime.now()
          .subtract(Duration(hours: index * 3))
          .toIso8601String(),
    };
  }

  Map<String, dynamic> _mockBadge(int index) {
    final badges = [
      {'name': 'Early Adopter', 'icon': '🚀', 'desc': 'Joined during beta'},
      {'name': 'Social Butterfly', 'icon': '🦋', 'desc': 'Joined 10+ events'},
      {'name': 'Event Creator', 'icon': '⭐', 'desc': 'Created 5+ events'},
      {'name': 'Explorer', 'icon': '🗺️', 'desc': 'Attended events in 5 locations'},
      {'name': 'Connector', 'icon': '🤝', 'desc': 'Connected with 50+ people'},
      {'name': 'Night Owl', 'icon': '🦉', 'desc': 'Attended 5 night events'},
    ];

    final badge = badges[index % badges.length];
    return {
      'id': 'badge_$index',
      'name': badge['name'],
      'icon': badge['icon'],
      'description': badge['desc'],
      'earnedAt': DateTime.now()
          .subtract(Duration(days: index * 7))
          .toIso8601String(),
      'rarity': ['common', 'uncommon', 'rare', 'epic', 'legendary'][index % 5],
    };
  }
}
