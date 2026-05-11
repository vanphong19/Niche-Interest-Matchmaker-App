import 'dart:convert';
import 'package:dio/dio.dart';
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

  Future<ProfileData> getProfile() async {
    final response = await _dio.get('/api/app/profile');
    final data = _unwrap(response.data);

    List<Map<String, dynamic>> interests = [];
    if (data['interests'] != null && data['interests'].toString().isNotEmpty) {
      try {
        final parsed = jsonDecode(data['interests']);
        if (parsed is List) {
          interests = parsed
              .map((e) => {'name': e.toString(), 'selected': true})
              .toList();
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
      avatarUrl:
          data['avatarUrl'] ?? data['AvatarUrl'] ?? 'https://i.pravatar.cc/300',
      interests: interests,
      createdCount: data['createdCount'] ?? data['CreatedCount'] ?? 0,
      joinedCount: data['joinedCount'] ?? data['JoinedCount'] ?? 0,
      friendsCount: data['friendsCount'] ?? data['FriendsCount'] ?? 0,
      badgesCount: data['badgesCount'] ?? data['BadgesCount'] ?? 0,
      reputationScore: data['reputationScore'] ?? data['ReputationScore'] ?? 0,
      badges: badges,
      pinnedMatchIds: (data['pinnedMatchIds'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
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
          interests = parsed
              .map((e) => {'name': e.toString(), 'selected': true})
              .toList();
        }
      } catch (_) {}
    }

    return ProfileData(
      id: userId,
      name: data['name'] ?? data['Name'] ?? '',
      username: (data['email'] ?? data['Email'] ?? '')
          .toString()
          .split('@')
          .first,
      bio: data['bio'] ?? data['Bio'] ?? '',
      location: data['location'] ?? data['Location'] ?? 'Viet Nam',
      email: data['email'] ?? data['Email'] ?? '',
      avatarUrl:
          data['avatarUrl'] ?? data['AvatarUrl'] ?? 'https://i.pravatar.cc/300',
      interests: interests,
      createdCount: data['createdCount'] ?? data['CreatedCount'] ?? 0,
      joinedCount: data['joinedCount'] ?? data['JoinedCount'] ?? 0,
      friendsCount: data['friendsCount'] ?? data['FriendsCount'] ?? 0,
      badgesCount: data['badgesCount'] ?? data['BadgesCount'] ?? 0,
      reputationScore: data['reputationScore'] ?? data['ReputationScore'] ?? 0,
      badges: [],
      pinnedMatchIds: (data['pinnedMatchIds'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
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
        'avatarUrl': profile.avatarUrl,
        'interests': interestsJson,
      },
    );
  }
}
