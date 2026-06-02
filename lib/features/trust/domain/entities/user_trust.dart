// lib/features/trust/domain/entities/user_trust.dart

import 'trust_badge.dart';
import 'trust_event_log.dart';

/// Model uy tín của một người dùng
class UserTrust {
  const UserTrust({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.score,
    required this.eventsJoined,
    required this.eventsHosted,
    required this.onTimeCheckins,
    required this.lateCheckins,
    required this.lastMinuteCancels,
    required this.noShows,
    required this.avgHostRating,
    required this.earnedBadges,
    required this.history,
    this.restrictedUntil,
  });

  final String userId;
  final String userName;
  final String? userAvatar;

  /// Điểm uy tín [0, 100], mặc định 70 cho user mới
  final int score;

  final int eventsJoined;
  final int eventsHosted;
  final int onTimeCheckins;
  final int lateCheckins;
  final int lastMinuteCancels;

  /// Số lần leo cây (no-show không báo trước)
  final int noShows;

  final double avgHostRating;

  final List<TrustBadgeType> earnedBadges;
  final List<TrustEventLog> history;

  /// Nếu không null → user đang bị hạn chế đăng ký event đến ngày này
  final DateTime? restrictedUntil;

  /// Tỷ lệ tham gia (0.0 – 1.0)
  double get attendanceRate {
    final total = eventsJoined + noShows + lastMinuteCancels;
    if (total == 0) return 1.0;
    return eventsJoined / total;
  }

  bool get isRestricted =>
      restrictedUntil != null && restrictedUntil!.isAfter(DateTime.now());

  UserTrust copyWith({
    int? score,
    int? eventsJoined,
    int? onTimeCheckins,
    int? lateCheckins,
    int? lastMinuteCancels,
    int? noShows,
    double? avgHostRating,
    List<TrustBadgeType>? earnedBadges,
    List<TrustEventLog>? history,
    DateTime? restrictedUntil,
  }) {
    return UserTrust(
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      score: (score ?? this.score).clamp(0, 100),
      eventsJoined: eventsJoined ?? this.eventsJoined,
      eventsHosted: eventsHosted,
      onTimeCheckins: onTimeCheckins ?? this.onTimeCheckins,
      lateCheckins: lateCheckins ?? this.lateCheckins,
      lastMinuteCancels: lastMinuteCancels ?? this.lastMinuteCancels,
      noShows: noShows ?? this.noShows,
      avgHostRating: avgHostRating ?? this.avgHostRating,
      earnedBadges: earnedBadges ?? this.earnedBadges,
      history: history ?? this.history,
      restrictedUntil: restrictedUntil ?? this.restrictedUntil,
    );
  }
}
