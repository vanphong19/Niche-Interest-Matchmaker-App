// lib/features/event/domain/entities/event.dart

enum EventCategory { sports, dining, social, arts, outdoor, gaming }

enum EventStatus { draft, active, cancelled, completed }

class EventLocation {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? placeId;
  final String? partnerLocationId;

  const EventLocation({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.placeId,
    this.partnerLocationId,
  });

  factory EventLocation.fromJson(Map<String, dynamic> json) {
    return EventLocation(
      name:
          json['name'] as String? ??
          json['locationName'] as String? ??
          json['placeName'] as String? ??
          '',
      address: json['address'] as String? ?? json['location'] as String? ?? '',
      latitude: (json['latitude'] ?? json['lat'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] ?? json['lng'] as num?)?.toDouble() ?? 0,
      placeId: json['placeId'] as String?,
      partnerLocationId:
          json['partnerLocationId']?.toString() ??
          json['PartnerLocationId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'placeId': placeId,
    'partnerLocationId': partnerLocationId,
  };
}

class Event {
  final String id;
  final String title;
  final String description;
  final EventCategory category;
  final String hostId;
  final String hostName;
  final String hostAvatar;
  final EventLocation location;
  final DateTime startDateTime;
  final DateTime? endDateTime;
  final int maxParticipants;
  final int currentParticipants;
  final List<String> participantIds;
  final List<String> participantAvatars;
  final EventStatus status;
  final bool isEliteOnly;
  final bool isPublic;
  final List<String> photoUrls;
  final double matchScore;
  final String? vibeTags;
  final bool isJoined;
  final bool isPending;
  final bool isHostFriend;
  final DateTime createdAt;
  final double? price;

  const Event({
    required this.id,
    required this.title,
    this.description = '',
    this.category = EventCategory.social,
    required this.hostId,
    this.hostName = '',
    this.hostAvatar = '',
    required this.location,
    required this.startDateTime,
    this.endDateTime,
    this.maxParticipants = 20,
    this.currentParticipants = 0,
    this.participantIds = const [],
    this.participantAvatars = const [],
    this.status = EventStatus.active,
    this.isEliteOnly = false,
    this.isPublic = true,
    this.photoUrls = const [],
    this.matchScore = 0,
    this.vibeTags,
    this.isJoined = false,
    this.isPending = false,
    this.isHostFriend = false,
    required this.createdAt,
    this.price,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    final locationData = json['location'] as Map<String, dynamic>?;
    final creator = json['creator'] as Map<String, dynamic>?;

    return Event(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description:
          json['description'] as String? ??
          json['Description'] as String? ??
          json['desc'] as String? ??
          json['about'] as String? ??
          '',
      category: _parseCategory(json['category'] as String?),
      hostId:
          creator?['id'] as String? ??
          creator?['Id'] as String? ??
          json['hostId'] as String? ??
          json['HostId'] as String? ??
          '',
      hostName:
          creator?['displayName'] as String? ??
          creator?['DisplayName'] as String? ??
          json['hostName'] as String? ??
          json['HostName'] as String? ??
          '',
      hostAvatar:
          creator?['avatarUrl'] as String? ??
          creator?['AvatarUrl'] as String? ??
          json['hostAvatar'] as String? ??
          json['HostAvatar'] as String? ??
          '',
      location: locationData != null
          ? EventLocation.fromJson(locationData)
          : EventLocation(
              name:
                  json['locationName'] as String? ??
                  json['LocationName'] as String? ??
                  '',
              address:
                  json['location'] as String? ??
                  json['Location'] as String? ??
                  json['address'] as String? ??
                  '',
              latitude:
                  (json['latitude'] ?? json['lat'] as num?)?.toDouble() ?? 0,
              longitude:
                  (json['longitude'] ?? json['lng'] as num?)?.toDouble() ?? 0,
            ),
      startDateTime:
          _parseDateTime(
            json['dateTime'] ??
                json['DateTime'] ??
                json['startDateTime'] ??
                json['StartDateTime'] ??
                json['startTime'] ??
                json['StartTime'] ??
                json['startTimeUtc'] ??
                json['StartTimeUtc'] ??
                json['start_time_utc'],
          ) ??
          DateTime.now(),
      endDateTime: _parseDateTime(
        json['endDateTime'] ??
            json['EndDateTime'] ??
            json['endTime'] ??
            json['EndTime'] ??
            json['endTimeUtc'] ??
            json['EndTimeUtc'] ??
            json['end_time_utc'],
      ),
      maxParticipants: json['maxParticipants'] as int? ?? 20,
      currentParticipants: json['currentParticipants'] as int? ?? 0,
      participantIds:
          ((json['participantIds'] ?? json['ParticipantIds']) as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      participantAvatars: _extractAvatars(json['participants']),
      status: _parseStatus(json['status'] as String?),
      isEliteOnly: json['isEliteOnly'] as bool? ?? false,
      isPublic: json['isPublic'] as bool? ?? true,
      photoUrls: _extractPhotos(json),
      matchScore: (json['matchScore'] as num?)?.toDouble() ?? 0,
      vibeTags: _parseVibeTags(
        json['vibeTags'] ?? json['VibeTags'] ?? json['tags'],
      ),
      isJoined: json['isJoined'] as bool? ?? false,
      isPending: json['isPending'] as bool? ?? false,
      isHostFriend:
          json['isHostFriend'] as bool? ??
          json['IsHostFriend'] as bool? ??
          false,
      createdAt:
          _parseDateTime(json['createdAt'] ?? json['CreatedAt']) ??
          DateTime.now(),
      price: (json['price'] as num?)?.toDouble(),
    );
  }

  String get distance {
    final hash = id.hashCode.abs();
    final dist = (hash % 45) / 10.0 + 0.5; // 0.5 to 5.0 km
    return dist.toStringAsFixed(1);
  }

  static EventCategory _parseCategory(String? str) {
    if (str == null) return EventCategory.social;
    switch (str.toLowerCase()) {
      case 'sports':
        return EventCategory.sports;
      case 'dining':
      case 'food':
        return EventCategory.dining;
      case 'social':
        return EventCategory.social;
      case 'arts':
      case 'art':
        return EventCategory.arts;
      case 'outdoor':
        return EventCategory.outdoor;
      case 'gaming':
      case 'games':
        return EventCategory.gaming;
      default:
        return EventCategory.social;
    }
  }

  static String? _parseVibeTags(dynamic tags) {
    if (tags == null) return null;
    if (tags is String) return tags;
    if (tags is List) return tags.map((e) => e.toString()).join(', ');
    return tags.toString();
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    if (parsed.isUtc) return parsed.toLocal();

    final hasExplicitOffset = RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(raw);
    if (hasExplicitOffset) return parsed.toLocal();

    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    ).toLocal();
  }

  static EventStatus _parseStatus(String? str) {
    switch (str) {
      case 'draft':
        return EventStatus.draft;
      case 'active':
        return EventStatus.active;
      case 'cancelled':
        return EventStatus.cancelled;
      case 'completed':
        return EventStatus.completed;
      default:
        return EventStatus.active;
    }
  }

  static List<String> _extractAvatars(dynamic participants) {
    if (participants is List) {
      return participants
          .take(5)
          .map((p) {
            if (p is Map) return p['avatarUrl'] as String? ?? '';
            return '';
          })
          .where((url) => url.isNotEmpty)
          .toList();
    }
    return [];
  }

  static List<String> _extractPhotos(Map<String, dynamic> json) {
    if (json['photoUrls'] is List) {
      return (json['photoUrls'] as List).map((e) => e.toString()).toList();
    }
    if (json['images'] is List) {
      return (json['images'] as List).map((e) => e.toString()).toList();
    }
    if (json['imageUrl'] is String) {
      return [json['imageUrl'] as String];
    }
    return const [];
  }

  String get categoryName {
    switch (category) {
      case EventCategory.sports:
        return 'Sports';
      case EventCategory.dining:
        return 'Dining';
      case EventCategory.social:
        return 'Social';
      case EventCategory.arts:
        return 'Arts';
      case EventCategory.outdoor:
        return 'Outdoors';
      case EventCategory.gaming:
        return 'Gaming';
    }
  }

  String get categoryEmoji {
    switch (category) {
      case EventCategory.sports:
        return '🏃';
      case EventCategory.dining:
        return '🍜';
      case EventCategory.social:
        return '💬';
      case EventCategory.arts:
        return '🎨';
      case EventCategory.outdoor:
        return '⛺';
      case EventCategory.gaming:
        return '🎮';
    }
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    EventCategory? category,
    String? hostId,
    String? hostName,
    String? hostAvatar,
    EventLocation? location,
    DateTime? startDateTime,
    DateTime? endDateTime,
    int? maxParticipants,
    int? currentParticipants,
    List<String>? participantIds,
    List<String>? participantAvatars,
    EventStatus? status,
    bool? isEliteOnly,
    bool? isPublic,
    List<String>? photoUrls,
    double? matchScore,
    String? vibeTags,
    bool? isJoined,
    bool? isPending,
    bool? isHostFriend,
    DateTime? createdAt,
    double? price,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      hostAvatar: hostAvatar ?? this.hostAvatar,
      location: location ?? this.location,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      participantIds: participantIds ?? this.participantIds,
      participantAvatars: participantAvatars ?? this.participantAvatars,
      status: status ?? this.status,
      isEliteOnly: isEliteOnly ?? this.isEliteOnly,
      isPublic: isPublic ?? this.isPublic,
      photoUrls: photoUrls ?? this.photoUrls,
      matchScore: matchScore ?? this.matchScore,
      vibeTags: vibeTags ?? this.vibeTags,
      isJoined: isJoined ?? this.isJoined,
      isPending: isPending ?? this.isPending,
      isHostFriend: isHostFriend ?? this.isHostFriend,
      createdAt: createdAt ?? this.createdAt,
      price: price ?? this.price,
    );
  }
}
