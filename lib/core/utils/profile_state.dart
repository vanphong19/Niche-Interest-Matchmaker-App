import 'package:flutter/foundation.dart';
import '../../features/event/data/services/event_api_service.dart';
import '../../features/profile/data/services/user_api_service.dart';
import '../../injection/injection_container.dart';

class ProfileData {
  final String id;
  final String name;
  final String username;
  final String bio;
  final String location;
  final String email;
  final String avatarUrl;
  final List<Map<String, dynamic>> interests;
  final int hostedCount;
  final int attendingCount;
  final int pastCount;
  final int friendsCount;
  final int badgesCount;
  final int reputationScore;
  final List<Map<String, dynamic>> badges;
  final List<String> pinnedMatchIds;
  final String friendshipStatus;

  const ProfileData({
    required this.id,
    required this.name,
    required this.username,
    required this.bio,
    required this.location,
    required this.email,
    required this.avatarUrl,
    required this.interests,
    this.hostedCount = 0,
    this.attendingCount = 0,
    this.pastCount = 0,
    this.friendsCount = 0,
    this.badgesCount = 0,
    this.reputationScore = 0,
    this.badges = const [],
    this.pinnedMatchIds = const [],
    this.friendshipStatus = 'None',
  });

  ProfileData copyWith({
    String? id,
    String? name,
    String? username,
    String? bio,
    String? location,
    String? email,
    String? avatarUrl,
    List<Map<String, dynamic>>? interests,
    int? hostedCount,
    int? attendingCount,
    int? pastCount,
    int? friendsCount,
    int? badgesCount,
    int? reputationScore,
    List<Map<String, dynamic>>? badges,
    List<String>? pinnedMatchIds,
    String? friendshipStatus,
  }) {
    return ProfileData(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      interests: interests ?? this.interests,
      hostedCount: hostedCount ?? this.hostedCount,
      attendingCount: attendingCount ?? this.attendingCount,
      pastCount: pastCount ?? this.pastCount,
      friendsCount: friendsCount ?? this.friendsCount,
      badgesCount: badgesCount ?? this.badgesCount,
      reputationScore: reputationScore ?? this.reputationScore,
      badges: badges ?? this.badges,
      pinnedMatchIds: pinnedMatchIds ?? this.pinnedMatchIds,
      friendshipStatus: friendshipStatus ?? this.friendshipStatus,
    );
  }
}

class ProfileState {
  ProfileState._();

  static final ValueNotifier<Set<String>> pinnedEventIdsNotifier =
      ValueNotifier(<String>{});

  static Future<void> init() async {
    try {
      final userApi = sl<UserApiService>();
      final profile = await userApi.getProfile();
      updateProfile(profile);
    } catch (e) {
      debugPrint('ProfileState init error: $e');
    }
  }

  static void reset() {
    notifier.value = _defaultData;
    pinnedEventIdsNotifier.value = {};
  }

  static final ProfileData _defaultData = ProfileData(
    id: '',
    name: 'User',
    username: 'user',
    bio: 'VibePulse Enthusiast',
    location: 'Unknown',
    email: '',
    avatarUrl: '',
    interests: [],
  );

  static final ValueNotifier<ProfileData> notifier = ValueNotifier(
    _defaultData,
  );

  static void updateProfile(ProfileData newData) {
    notifier.value = newData;
    pinnedEventIdsNotifier.value = newData.pinnedMatchIds.toSet();
  }

  static bool isEventPinned(String eventId) {
    return pinnedEventIdsNotifier.value.contains(eventId);
  }

  static void togglePinnedEvent(String eventId) {
    final next = Set<String>.from(pinnedEventIdsNotifier.value);
    final service = sl<EventApiService>();

    if (next.contains(eventId)) {
      next.remove(eventId);
      service.unpinEvent(eventId);
    } else {
      next.add(eventId);
      service.pinEvent(eventId);
    }

    pinnedEventIdsNotifier.value = next;
    // We update the notifier immediately for UI responsiveness
  }
}
