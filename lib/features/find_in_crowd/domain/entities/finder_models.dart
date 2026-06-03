import '../../presentation/models/finder_location_ui_model.dart';

enum FinderAvailability {
  available,
  self,
  notCheckedIn,
  offline,
  busy,
  alreadyFindingWithMe,
  notAllowed,
}

enum FinderRequestStatus { pending, accepted, declined, expired, cancelled }

enum FinderSessionStatus { active, stopped, expired }

class EventFinderMember {
  const EventFinderMember({
    required this.userId,
    required this.fullName,
    required this.eventStatus,
    required this.checkInStatus,
    required this.isOnline,
    required this.finderAvailability,
    this.avatarUrl,
    this.activeFinderSessionId,
    this.role,
  });

  factory EventFinderMember.fromJson(Map<String, dynamic> json) {
    return EventFinderMember(
      userId: _read(json, ['userId', 'UserId', 'id', 'Id']),
      fullName: _read(json, ['fullName', 'FullName', 'name', 'Name']),
      avatarUrl: _nullableRead(json, ['avatarUrl', 'AvatarUrl']),
      eventStatus: _read(json, ['eventStatus', 'EventStatus'], 'joined'),
      checkInStatus: _read(json, [
        'checkInStatus',
        'CheckInStatus',
      ], 'checked_in'),
      isOnline: _readBool(json, ['isOnline', 'IsOnline'], true),
      finderAvailability: _parseAvailability(
        _read(json, [
          'finderAvailability',
          'FinderAvailability',
        ], 'available'),
      ),
      activeFinderSessionId: _nullableRead(json, [
        'activeFinderSessionId',
        'ActiveFinderSessionId',
      ]),
      role: _nullableRead(json, ['role', 'Role']),
    );
  }

  final String userId;
  final String fullName;
  final String? avatarUrl;
  final String eventStatus;
  final String checkInStatus;
  final bool isOnline;
  final FinderAvailability finderAvailability;
  final String? activeFinderSessionId;
  final String? role;

  bool get canFind => finderAvailability == FinderAvailability.available;
  bool get canResume =>
      finderAvailability == FinderAvailability.alreadyFindingWithMe &&
      activeFinderSessionId != null &&
      activeFinderSessionId!.isNotEmpty;

  String get actionLabel {
    switch (finderAvailability) {
      case FinderAvailability.available:
        return 'Find';
      case FinderAvailability.self:
        return 'Self';
      case FinderAvailability.notCheckedIn:
        return 'Not checked in';
      case FinderAvailability.offline:
        return 'Unavailable';
      case FinderAvailability.busy:
        return 'Busy';
      case FinderAvailability.alreadyFindingWithMe:
        return 'Resume';
      case FinderAvailability.notAllowed:
        return 'Not allowed';
    }
  }

  String get statusLabel {
    if (checkInStatus.toLowerCase().contains('checked')) {
      return 'Checked in';
    }
    if (!isOnline) return 'Offline';
    return role ?? 'Participant';
  }
}

class FinderParticipant {
  const FinderParticipant({
    required this.userId,
    required this.fullName,
    this.avatarUrl,
  });

  factory FinderParticipant.fromJson(Map<String, dynamic> json) {
    return FinderParticipant(
      userId: _read(json, ['userId', 'UserId', 'id', 'Id']),
      fullName: _read(json, ['fullName', 'FullName', 'name', 'Name']),
      avatarUrl: _nullableRead(json, ['avatarUrl', 'AvatarUrl']),
    );
  }

  final String userId;
  final String fullName;
  final String? avatarUrl;

  String get firstName {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? 'Partner' : parts.first;
  }
}

class FinderRequest {
  const FinderRequest({
    required this.requestId,
    required this.eventId,
    required this.receiverId,
    required this.status,
    required this.expiresAt,
    this.eventName,
    this.venueName,
    this.requester,
    this.requesterId,
  });

  factory FinderRequest.fromJson(Map<String, dynamic> json) {
    final requesterJson = json['requester'] ?? json['Requester'];
    return FinderRequest(
      requestId: _read(json, ['requestId', 'RequestId', 'id', 'Id']),
      eventId: _read(json, ['eventId', 'EventId']),
      eventName: _nullableRead(json, ['eventName', 'EventName']),
      venueName: _nullableRead(json, ['venueName', 'VenueName']),
      requester: requesterJson is Map
          ? FinderParticipant.fromJson(Map<String, dynamic>.from(requesterJson))
          : null,
      requesterId: _nullableRead(json, ['requesterId', 'RequesterId']),
      receiverId: _read(json, ['receiverId', 'ReceiverId']),
      status: _parseRequestStatus(_read(json, ['status', 'Status'], 'pending')),
      expiresAt:
          DateTime.tryParse(_read(json, ['expiresAt', 'ExpiresAt'])) ??
          DateTime.now().add(const Duration(minutes: 2)),
    );
  }

  final String requestId;
  final String eventId;
  final String? eventName;
  final String? venueName;
  final FinderParticipant? requester;
  final String? requesterId;
  final String receiverId;
  final FinderRequestStatus status;
  final DateTime expiresAt;
}

class FinderSession {
  const FinderSession({
    required this.sessionId,
    required this.eventId,
    required this.partner,
    required this.status,
    required this.expiresAt,
    this.startedAt,
  });

  factory FinderSession.fromJson(Map<String, dynamic> json) {
    final data = json['session'] is Map
        ? Map<String, dynamic>.from(json['session'] as Map)
        : json;
    final partnerJson = data['partner'] ?? data['Partner'];
    return FinderSession(
      sessionId: _read(data, ['sessionId', 'SessionId', 'id', 'Id']),
      eventId: _read(data, ['eventId', 'EventId']),
      partner: partnerJson is Map
          ? FinderParticipant.fromJson(Map<String, dynamic>.from(partnerJson))
          : FinderParticipant(
              userId: _read(data, ['partnerId', 'PartnerId']),
              fullName: _read(data, ['partnerName', 'PartnerName'], 'Partner'),
              avatarUrl: _nullableRead(data, ['partnerAvatarUrl']),
            ),
      status: _parseSessionStatus(_read(data, ['status', 'Status'], 'active')),
      startedAt: DateTime.tryParse(_read(data, ['startedAt', 'StartedAt'])),
      expiresAt:
          DateTime.tryParse(_read(data, ['expiresAt', 'ExpiresAt'])) ??
          DateTime.now().add(const Duration(minutes: 10)),
    );
  }

  final String sessionId;
  final String eventId;
  final FinderParticipant partner;
  final FinderSessionStatus status;
  final DateTime? startedAt;
  final DateTime expiresAt;

  bool get isActive => status == FinderSessionStatus.active;
}

class FinderLocation {
  const FinderLocation({
    required this.sessionId,
    required this.userId,
    required this.location,
  });

  factory FinderLocation.fromJson(Map<String, dynamic> json) {
    return FinderLocation(
      sessionId: _read(json, ['sessionId', 'SessionId']),
      userId: _read(json, ['userId', 'UserId']),
      location: FinderLocationUiModel(
        latitude: _readDouble(json, ['latitude', 'Latitude']),
        longitude: _readDouble(json, ['longitude', 'Longitude']),
        accuracyMeters: _readDouble(json, [
          'accuracyMeters',
          'AccuracyMeters',
          'locationAccuracyMeters',
        ]),
        headingDegrees: _readNullableDouble(json, [
          'headingDegrees',
          'HeadingDegrees',
        ]),
        capturedAt:
            DateTime.tryParse(_read(json, ['capturedAt', 'CapturedAt'])) ??
            DateTime.now(),
      ),
    );
  }

  final String sessionId;
  final String userId;
  final FinderLocationUiModel location;
}

Map<String, dynamic> locationToJson(FinderLocationUiModel location) {
  return {
    'latitude': location.latitude,
    'longitude': location.longitude,
    'accuracyMeters': location.accuracyMeters,
    'headingDegrees': location.headingDegrees,
    'capturedAt': location.capturedAt.toUtc().toIso8601String(),
  };
}

FinderAvailability _parseAvailability(String value) {
  final normalized = value.toLowerCase().replaceAll('-', '_');
  switch (normalized) {
    case 'self':
      return FinderAvailability.self;
    case 'not_checked_in':
    case 'notcheckedin':
      return FinderAvailability.notCheckedIn;
    case 'offline':
      return FinderAvailability.offline;
    case 'busy':
      return FinderAvailability.busy;
    case 'already_finding_with_me':
    case 'alreadyfindingwithme':
      return FinderAvailability.alreadyFindingWithMe;
    case 'not_allowed':
    case 'notallowed':
      return FinderAvailability.notAllowed;
    default:
      return FinderAvailability.available;
  }
}

FinderRequestStatus _parseRequestStatus(String value) {
  switch (value.toLowerCase()) {
    case 'accepted':
      return FinderRequestStatus.accepted;
    case 'declined':
      return FinderRequestStatus.declined;
    case 'expired':
      return FinderRequestStatus.expired;
    case 'cancelled':
    case 'canceled':
      return FinderRequestStatus.cancelled;
    default:
      return FinderRequestStatus.pending;
  }
}

FinderSessionStatus _parseSessionStatus(String value) {
  switch (value.toLowerCase()) {
    case 'stopped':
      return FinderSessionStatus.stopped;
    case 'expired':
      return FinderSessionStatus.expired;
    default:
      return FinderSessionStatus.active;
  }
}

String _read(
  Map<String, dynamic> json,
  List<String> keys, [
  String fallback = '',
]) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().isNotEmpty) return value.toString();
  }
  return fallback;
}

String? _nullableRead(Map<String, dynamic> json, List<String> keys) {
  final value = _read(json, keys);
  return value.isEmpty ? null : value;
}

bool _readBool(
  Map<String, dynamic> json,
  List<String> keys, [
  bool fallback = false,
]) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
  }
  return fallback;
}

double _readDouble(Map<String, dynamic> json, List<String> keys) {
  return _readNullableDouble(json, keys) ?? 0;
}

double? _readNullableDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
  }
  return null;
}
