import 'package:dio/dio.dart';

import '../../domain/entities/trust_badge.dart';
import '../../domain/entities/trust_event_log.dart';
import '../../domain/entities/user_trust.dart';

class ReputationApiService {
  ReputationApiService(this._dio);

  final Dio _dio;

  Future<UserTrust> getMyTrust({
    String userName = 'You',
    String? avatarUrl,
  }) async {
    final summaryResponse = await _dio.get('/api/app/profile/reputation');
    final historyResponse = await _dio.get(
      '/api/app/profile/reputation/history',
      queryParameters: {'take': 50},
    );

    final summary = _unwrapMap(summaryResponse.data);
    final history = _unwrapList(historyResponse.data)
        .map((item) => _mapHistoryItem(Map<String, dynamic>.from(item as Map)))
        .toList();

    return _mapSummary(
      summary,
      history: history,
      fallbackUserName: userName,
      avatarUrl: avatarUrl,
    );
  }

  Future<UserTrust> getUserTrust(
    String userId, {
    required String userName,
    String? avatarUrl,
  }) async {
    final response = await _dio.get('/api/app/profile/$userId/reputation');
    return _mapSummary(
      _unwrapMap(response.data),
      history: const [],
      fallbackUserName: userName,
      avatarUrl: avatarUrl,
    );
  }

  Map<String, dynamic> _unwrapMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nested = data['data'] ?? data['Data'];
      if (nested is Map<String, dynamic>) return nested;
      return data;
    }
    return {};
  }

  List<dynamic> _unwrapList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final nested = data['data'] ?? data['Data'];
      if (nested is List) return nested;
    }
    return const [];
  }

  UserTrust _mapSummary(
    Map<String, dynamic> json, {
    required List<TrustEventLog> history,
    required String fallbackUserName,
    String? avatarUrl,
  }) {
    final score = _asInt(json['reputationScore'] ?? json['ReputationScore']);
    final joinedEvents = _asInt(json['joinedEvents'] ?? json['JoinedEvents']);
    final validCheckIns = _asInt(
      json['validCheckIns'] ?? json['ValidCheckIns'],
    );
    final missedEvents = _asInt(json['missedEvents'] ?? json['MissedEvents']);
    final badges = _unwrapList(json['badges'] ?? json['Badges'])
        .whereType<Map>()
        .where((badge) {
          final status = (badge['status'] ?? badge['Status'] ?? '')
              .toString()
              .toLowerCase();
          return status == 'earned';
        })
        .map((badge) => _mapBadgeType(
              (badge['code'] ?? badge['Code'] ?? '').toString(),
            ))
        .whereType<TrustBadgeType>()
        .toList();

    return UserTrust(
      userId: (json['userId'] ?? json['UserId'] ?? '').toString(),
      userName: fallbackUserName,
      userAvatar: avatarUrl,
      score: score,
      eventsJoined: joinedEvents,
      eventsHosted: 0,
      onTimeCheckins: validCheckIns,
      lastMinuteCancels: 0,
      noShows: missedEvents,
      avgHostRating: 0,
      earnedBadges: badges,
      history: history,
      restrictedUntil: score < 40
          ? DateTime.now().add(const Duration(days: 7))
          : null,
    );
  }

  TrustEventLog _mapHistoryItem(Map<String, dynamic> json) {
    final type = (json['type'] ?? json['Type'] ?? '').toString();
    final points = _asInt(json['points'] ?? json['Points']);
    final occurredAt = DateTime.tryParse(
          (json['occurredAtUtc'] ?? json['OccurredAtUtc'] ?? '').toString(),
        )?.toLocal() ??
        DateTime.now();

    return TrustEventLog(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      reason: type == 'no_show'
          ? TrustLogReason.noShow
          : TrustLogReason.onTimeCheckin,
      delta: points,
      timestamp: occurredAt,
      eventName:
          (json['matchName'] ?? json['MatchName'] ?? json['title'] ?? 'Event')
              .toString(),
    );
  }

  TrustBadgeType? _mapBadgeType(String code) {
    switch (code) {
      case 'punctual':
        return TrustBadgeType.onTime;
      case 'active_host':
        return TrustBadgeType.activeHost;
      case 'reliable':
        return TrustBadgeType.noNoShow;
      case 'streak_keeper':
        return TrustBadgeType.committed;
      default:
        return null;
    }
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
