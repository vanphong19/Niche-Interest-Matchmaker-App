import 'package:flutter/foundation.dart';

class ProfileData {
  final String name;
  final String username;
  final String bio;
  final String location;
  final String email;
  final String avatarUrl;
  final List<Map<String, dynamic>> interests;

  const ProfileData({
    required this.name,
    required this.username,
    required this.bio,
    required this.location,
    required this.email,
    required this.avatarUrl,
    required this.interests,
  });

  ProfileData copyWith({
    String? name,
    String? username,
    String? bio,
    String? location,
    String? email,
    String? avatarUrl,
    List<Map<String, dynamic>>? interests,
  }) {
    return ProfileData(
      name: name ?? this.name,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      interests: interests ?? this.interests,
    );
  }
}

class ProfileState {
  ProfileState._();

  static final ValueNotifier<Set<String>> pinnedEventIdsNotifier =
      ValueNotifier(<String>{'evt-002', 'evt-003', 'evt-004', 'evt-005'});

  static final ValueNotifier<ProfileData> notifier = ValueNotifier(
    ProfileData(
      name: 'Marcus Chen',
      username: 'marcuschen',
      bio:
          'Tech enthusiast and weekend hiker. Building community vibes in the concrete jungle. 🌿',
      location: 'Ho Chi Minh City',
      email: 'marcus@vibepulse.app',
      avatarUrl: 'https://i.pravatar.cc/300?u=user_1',
      interests: [
        {'name': 'Sports', 'icon': 'sports_basketball', 'selected': true},
        {'name': 'Music', 'icon': 'music_note', 'selected': true},
        {'name': 'Tech', 'icon': 'computer', 'selected': true},
        {'name': 'Gaming', 'icon': 'sports_esports', 'selected': true},
        {'name': 'Dining', 'icon': 'restaurant', 'selected': true},
        {'name': 'Arts', 'icon': 'palette', 'selected': false},
        {'name': 'Outdoors', 'icon': 'terrain', 'selected': false},
        {'name': 'Social', 'icon': 'people', 'selected': false},
        {'name': 'Photography', 'icon': 'camera_alt', 'selected': false},
        {'name': 'Travel', 'icon': 'flight', 'selected': false},
        {'name': 'Fitness', 'icon': 'fitness_center', 'selected': false},
        {'name': 'Movies', 'icon': 'movie', 'selected': false},
      ],
    ),
  );

  static void updateProfile(ProfileData newData) {
    notifier.value = newData;
  }

  static bool isEventPinned(String eventId) {
    return pinnedEventIdsNotifier.value.contains(eventId);
  }

  static void togglePinnedEvent(String eventId) {
    final next = Set<String>.from(pinnedEventIdsNotifier.value);
    if (!next.add(eventId)) {
      next.remove(eventId);
    }
    pinnedEventIdsNotifier.value = next;
  }
}
