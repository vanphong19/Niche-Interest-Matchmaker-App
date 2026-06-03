// lib/features/trust/domain/services/reputation_service.dart

import 'package:flutter/material.dart';
import '../entities/trust_badge.dart';
import '../entities/trust_event_log.dart';
import '../entities/user_trust.dart';

// ─── Cấp độ uy tín ────────────────────────────────────────────────────────────

enum TrustLevel {
  gold, // 90–100
  blue, // 75–89
  yellow, // 60–74
  orange, // 40–59
  red, // 0–39
}

class TrustLevelData {
  const TrustLevelData({
    required this.level,
    required this.label,
    required this.emoji,
    required this.color,
    required this.gradientColors,
  });

  final TrustLevel level;
  final String label;
  final String emoji;
  final Color color;
  final List<Color> gradientColors;
}

// ─── ReputationService ────────────────────────────────────────────────────────

class ReputationService {
  ReputationService._();

  // ── 1. Lấy cấp độ theo điểm ────────────────────────────────────────────────

  static TrustLevelData getLevel(int score) {
    if (score >= 90) {
      return const TrustLevelData(
        level: TrustLevel.gold,
        label: 'Person who keeps the promise',
        emoji: '🏆',
        color: Color(0xFF22C55E),
        gradientColors: [
          Color(0xFF16A34A),
          Color(0xFF22C55E),
          Color(0xFF4ADE80),
        ],
      );
    } else if (score >= 75) {
      return const TrustLevelData(
        level: TrustLevel.blue,
        label: 'Trusted teammate',
        emoji: '💎',
        color: Color(0xFF3B82F6),
        gradientColors: [
          Color(0xFF1D4ED8),
          Color(0xFF3B82F6),
          Color(0xFF60A5FA),
        ],
      );
    } else if (score >= 60) {
      return const TrustLevelData(
        level: TrustLevel.yellow,
        label: 'Person who needs to improve',
        emoji: '⚡',
        color: Color(0xFFF59E0B),
        gradientColors: [
          Color(0xFFD97706),
          Color(0xFFF59E0B),
          Color(0xFFFBBF24),
        ],
      );
    } else if (score >= 40) {
      return const TrustLevelData(
        level: TrustLevel.orange,
        label: 'Person who is inconsistent',
        emoji: '🌊',
        color: Color(0xFFF97316),
        gradientColors: [
          Color(0xFFEA580C),
          Color(0xFFF97316),
          Color(0xFFFB923C),
        ],
      );
    } else {
      return const TrustLevelData(
        level: TrustLevel.red,
        label: 'Person who is a danger',
        emoji: '🚨',
        color: Color(0xFFEF4444),
        gradientColors: [
          Color(0xFFDC2626),
          Color(0xFFEF4444),
          Color(0xFFF87171),
        ],
      );
    }
  }

  // ── 2. Tính delta khi check-in ─────────────────────────────────────────────

  /// Trả về (delta, reason)
  /// - Đúng giờ (trễ <= 0 phút): +5
  /// - Trễ dưới 15 phút: +2
  /// - Trễ trên 30 phút: 0
  static (int delta, TrustLogReason reason) calculateCheckinDelta(
    DateTime checkInTime,
    DateTime eventStart,
  ) {
    final lateMinutes = checkInTime.difference(eventStart).inMinutes;
    if (lateMinutes <= 0) {
      return (5, TrustLogReason.onTimeCheckin);
    } else if (lateMinutes < 15) {
      return (2, TrustLogReason.lateCheckin15);
    } else if (lateMinutes < 30) {
      return (0, TrustLogReason.lateCheckin15);
    } else {
      return (0, TrustLogReason.lateCheckin30);
    }
  }

  // ── 3. Tính delta khi hủy tham gia ────────────────────────────────────────

  /// - Hủy trước 12 tiếng: 0
  /// - Hủy trong vòng 12 tiếng: -5
  static (int delta, TrustLogReason reason) calculateCancelDelta(
    DateTime cancelAt,
    DateTime eventStart,
  ) {
    final hoursLeft = eventStart.difference(cancelAt).inHours;
    if (hoursLeft >= 12) {
      return (0, TrustLogReason.lastMinuteCancel);
    } else {
      return (-5, TrustLogReason.lastMinuteCancel);
    }
  }

  // ── 4. Tính delta từ host review ──────────────────────────────────────────

  /// - 5 sao: +5
  /// - 3–4 sao: +2
  /// - < 3 sao: -3
  static (int delta, TrustLogReason reason) calculateReviewDelta(int stars) {
    if (stars == 5) {
      return (5, TrustLogReason.reviewFiveStar);
    } else if (stars >= 3) {
      return (2, TrustLogReason.reviewGoodStar);
    } else {
      return (-3, TrustLogReason.reviewBadStar);
    }
  }

  // ── 5. Kiểm tra bị hạn chế ────────────────────────────────────────────────

  static bool isRestricted(UserTrust trust) => trust.isRestricted;

  // ── 6. Số no-show trong 30 ngày ───────────────────────────────────────────

  static int getNoShowsLast30Days(List<TrustEventLog> logs) {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return logs
        .where(
          (log) =>
              log.reason == TrustLogReason.noShow &&
              log.timestamp.isAfter(cutoff),
        )
        .length;
  }

  // ── 7. Tính badge đã đạt ──────────────────────────────────────────────────

  static List<TrustBadgeType> computeBadges(UserTrust trust) {
    final earned = <TrustBadgeType>[];

    // 🕐 Người đúng hẹn: check-in đúng giờ >= 5 lần
    if (trust.onTimeCheckins >= 5) earned.add(TrustBadgeType.onTime);

    // 🎯 Chủ kèo năng nổ: tạo >= 3 event
    if (trust.eventsHosted >= 3) earned.add(TrustBadgeType.activeHost);

    // 🌿 Không leo cây: 0 no-show trong 30 ngày
    if (getNoShowsLast30Days(trust.history) == 0) {
      earned.add(TrustBadgeType.noNoShow);
    }

    // 🌟 Bạn đồng hành vàng: rating >= 4.8
    if (trust.avgHostRating >= 4.8) earned.add(TrustBadgeType.goldenCompanion);

    // 💪 Người giữ kèo: tham gia >= 10 event
    if (trust.eventsJoined >= 10) earned.add(TrustBadgeType.committed);

    return earned;
  }

  // ── 8. Apply điểm mới (clamp 0–100) ──────────────────────────────────────

  static int applyDelta(int currentScore, int delta) {
    return (currentScore + delta).clamp(0, 100);
  }

  // ── 9. Kiểm tra phạt restrict ─────────────────────────────────────────────

  /// Nếu no-show >= 3 trong 30 ngày → restrict 3 ngày
  static DateTime? checkRestriction(UserTrust trust) {
    final noShowsRecent = getNoShowsLast30Days(trust.history);
    if (noShowsRecent >= 3) {
      return DateTime.now().add(const Duration(days: 3));
    }
    return null;
  }
}

// ─── Mock Data ────────────────────────────────────────────────────────────────

final UserTrust mockUserTrust = UserTrust(
  userId: 'mock-user-001',
  userName: 'Minh Phúc',
  userAvatar: null,
  score: 82,
  eventsJoined: 14,
  eventsHosted: 4,
  onTimeCheckins: 11,
  lateCheckins: 1,
  lastMinuteCancels: 1,
  noShows: 2,
  avgHostRating: 4.6,
  earnedBadges: const [
    TrustBadgeType.onTime,
    TrustBadgeType.activeHost,
    TrustBadgeType.committed,
  ],
  history: [
    TrustEventLog(
      id: 'log-1',
      reason: TrustLogReason.onTimeCheckin,
      delta: 5,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      eventName: 'Hiking Núi Bà Đen',
    ),
    TrustEventLog(
      id: 'log-2',
      reason: TrustLogReason.reviewFiveStar,
      delta: 5,
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      eventName: 'Cafe Hopping Q1',
    ),
    TrustEventLog(
      id: 'log-3',
      reason: TrustLogReason.lateCheckin15,
      delta: 2,
      timestamp: DateTime.now().subtract(const Duration(days: 5)),
      eventName: 'Chạy Bộ Sáng',
    ),
    TrustEventLog(
      id: 'log-4',
      reason: TrustLogReason.noShow,
      delta: -15,
      timestamp: DateTime.now().subtract(const Duration(days: 10)),
      eventName: 'Picnic Thủ Lệ',
    ),
    TrustEventLog(
      id: 'log-5',
      reason: TrustLogReason.lastMinuteCancel,
      delta: -5,
      timestamp: DateTime.now().subtract(const Duration(days: 18)),
      eventName: 'Movie Night',
    ),
    TrustEventLog(
      id: 'log-6',
      reason: TrustLogReason.onTimeCheckin,
      delta: 5,
      timestamp: DateTime.now().subtract(const Duration(days: 20)),
      eventName: 'Board Game Night',
    ),
  ],
);

/// Mock user có điểm thấp – để test recovery missions & cảnh báo
final UserTrust mockLowTrustUser = UserTrust(
  userId: 'mock-user-002',
  userName: 'Trung Kiên',
  userAvatar: null,
  score: 35,
  eventsJoined: 4,
  eventsHosted: 0,
  onTimeCheckins: 2,
  lateCheckins: 1,
  lastMinuteCancels: 3,
  noShows: 4,
  avgHostRating: 2.8,
  earnedBadges: const [],
  history: [
    TrustEventLog(
      id: 'log-a',
      reason: TrustLogReason.noShow,
      delta: -15,
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      eventName: 'Hiking Tà Năng',
    ),
    TrustEventLog(
      id: 'log-b',
      reason: TrustLogReason.noShow,
      delta: -15,
      timestamp: DateTime.now().subtract(const Duration(days: 8)),
      eventName: 'Cắm Trại Biển',
    ),
    TrustEventLog(
      id: 'log-c',
      reason: TrustLogReason.noShow,
      delta: -15,
      timestamp: DateTime.now().subtract(const Duration(days: 12)),
      eventName: 'Đạp Xe Hồ Tây',
    ),
    TrustEventLog(
      id: 'log-d',
      reason: TrustLogReason.reviewBadStar,
      delta: -3,
      timestamp: DateTime.now().subtract(const Duration(days: 15)),
      eventName: 'Cafe Study',
    ),
  ],
  restrictedUntil: DateTime.now().add(const Duration(days: 2)),
);
