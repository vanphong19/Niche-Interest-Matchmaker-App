import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/utils/profile_state.dart';

class UserApiService {
  final Dio _dio;

  UserApiService(this._dio);

  Map<String, dynamic> _unwrap(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('data') &&
          responseData['data'] is Map<String, dynamic>) {
        return responseData['data'] as Map<String, dynamic>;
      }
      return responseData;
    }
    return {};
  }

  String? _extractUrl(dynamic responseData) {
    final data = _unwrap(responseData);
    return data['url']?.toString() ?? data['Url']?.toString();
  }

  Future<ProfileData> getProfile() async {
    final response = await _dio.get('/api/app/profile');
    final data = _unwrap(response.data);

    List<Map<String, dynamic>> interests = [];
    if (data['interests'] != null && data['interests'].toString().isNotEmpty) {
      try {
        final parsed = jsonDecode(data['interests']);
        if (parsed is List) {
          interests = parsed.map((e) {
            if (e is Map) {
              return {
                'name': (e['name'] ?? e['Name'] ?? '').toString(),
                'icon': (e['icon'] ?? e['Icon'] ?? 'local_activity').toString(),
                'selected': e['selected'] ?? e['Selected'] ?? true,
              };
            }
            return {
              'name': e.toString(),
              'icon': 'local_activity',
              'selected': true,
            };
          }).toList();
        }
      } catch (_) {}
    }

    List<Map<String, dynamic>> badges = [];
    if (data['badges'] != null && data['badges'] is List) {
      badges = (data['badges'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    }

    return ProfileData(
      id: (data['id'] ?? data['Id'])?.toString() ?? '',
      name: data['name'] ?? data['Name'] ?? '',
      username: (data['email'] ?? data['Email'] ?? '')
          .toString()
          .split('@')
          .first,
      bio: data['bio'] ?? data['Bio'] ?? '',
      location: data['location'] ?? data['Location'] ?? 'Viet Nam',
      email: data['email'] ?? data['Email'] ?? '',
      avatarUrl: data['avatarUrl'] ?? data['AvatarUrl'] ?? '',
      interests: interests,
      hostedCount: data['hostedCount'] ?? data['HostedCount'] ?? 0,
      attendingCount: data['attendingCount'] ?? data['AttendingCount'] ?? 0,
      pastCount: data['pastCount'] ?? data['PastCount'] ?? 0,
      friendsCount: data['friendsCount'] ?? data['FriendsCount'] ?? 0,
      badgesCount: data['badgesCount'] ?? data['BadgesCount'] ?? 0,
      reputationScore: data['reputationScore'] ?? data['ReputationScore'] ?? 0,
      badges: badges,
      pinnedMatchIds:
          ((data['pinnedMatchIds'] ?? data['PinnedMatchIds']) as List? ?? [])
              .map((e) => e.toString())
              .toList(),
      friendshipStatus:
          data['friendshipStatus'] ?? data['FriendshipStatus'] ?? 'None',
    );
  }

  Future<ProfileData> getOtherProfile(String userId) async {
    final response = await _dio.get('/api/app/profile/$userId');
    final data = _unwrap(response.data);

    List<Map<String, dynamic>> interests = [];
    if (data['interests'] != null && data['interests'].toString().isNotEmpty) {
      try {
        final parsed = jsonDecode(data['interests']);
        if (parsed is List) {
          interests = parsed.map((e) {
            if (e is Map) {
              return {
                'name': (e['name'] ?? e['Name'] ?? '').toString(),
                'icon': (e['icon'] ?? e['Icon'] ?? 'local_activity').toString(),
                'selected': e['selected'] ?? e['Selected'] ?? true,
              };
            }
            return {
              'name': e.toString(),
              'icon': 'local_activity',
              'selected': true,
            };
          }).toList();
        }
      } catch (_) {}
    }

    List<Map<String, dynamic>> badges = [];
    if (data['badges'] != null && data['badges'] is List) {
      badges = (data['badges'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return ProfileData(
      id: (data['id'] ?? data['Id'] ?? userId).toString(),
      name: data['name'] ?? data['Name'] ?? '',
      username: (data['email'] ?? data['Email'] ?? '')
          .toString()
          .split('@')
          .first,
      bio: data['bio'] ?? data['Bio'] ?? '',
      location: data['location'] ?? data['Location'] ?? 'Viet Nam',
      email: data['email'] ?? data['Email'] ?? '',
      avatarUrl: data['avatarUrl'] ?? data['AvatarUrl'] ?? '',
      interests: interests,
      hostedCount: data['hostedCount'] ?? data['HostedCount'] ?? 0,
      attendingCount: data['attendingCount'] ?? data['AttendingCount'] ?? 0,
      pastCount: data['pastCount'] ?? data['PastCount'] ?? 0,
      friendsCount: data['friendsCount'] ?? data['FriendsCount'] ?? 0,
      badgesCount: data['badgesCount'] ?? data['BadgesCount'] ?? 0,
      reputationScore: data['reputationScore'] ?? data['ReputationScore'] ?? 0,
      badges: badges,
      pinnedMatchIds:
          ((data['pinnedMatchIds'] ?? data['PinnedMatchIds']) as List? ?? [])
              .map((e) => e.toString())
              .toList(),
      friendshipStatus:
          data['friendshipStatus'] ?? data['FriendshipStatus'] ?? 'None',
    );
  }

  Future<void> updateProfile(ProfileData profile) async {
    final interestsJson = jsonEncode(
      profile.interests
          .where((i) => i['selected'] == true)
          .map((i) => i['name'])
          .toList(),
    );

    await _dio.put(
      '/api/app/profile',
      data: {
        'name': profile.name,
        'email': profile.email,
        'bio': profile.bio,
        'location': profile.location,
        'avatarUrl': profile.avatarUrl,
        'interests': interestsJson,
      },
    );
  }

  Future<String?> uploadAvatar(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post(
        '/api/app/profile/upload-avatar',
        data: formData,
      );
      return _extractUrl(response.data);
    } catch (e) {
      debugPrint('Upload Avatar Error: $e');
      return null;
    }
  }

  Future<String?> uploadAvatarBytes(Uint8List bytes, String fileName) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });
      final response = await _dio.post(
        '/api/app/profile/upload-avatar',
        data: formData,
      );
      return _extractUrl(response.data);
    } catch (e) {
      debugPrint('Upload Avatar Bytes Error: $e');
      return null;
    }
  }

  Future<void> requestFriend(String userId) async {
    await _dio.post('/api/app/profile/friends/$userId');
  }

  Future<void> unfriend(String userId) async {
    await _dio.delete('/api/app/profile/friends/$userId');
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final response = await _dio.get('/api/app/profile/notifications');
    final data =
        response.data is Map<String, dynamic> &&
            (response.data as Map<String, dynamic>)['data'] is List
        ? (response.data as Map<String, dynamic>)['data'] as List
        : response.data is List
        ? response.data as List
        : [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> actOnNotification(String notificationId, String action) async {
    await _dio.post(
      '/api/app/profile/notifications/$notificationId/action',
      queryParameters: {'action': action},
    );
  }

  Future<void> deleteAccount() async {
    await _dio.delete('/api/app/profile/account');
  }
}
