// lib/features/trust/domain/entities/trust_event_log.dart

/// Lý do thay đổi điểm uy tín
enum TrustLogReason {
  onTimeCheckin,        // Check-in đúng giờ
  lateCheckin15,        // Trễ dưới 15 phút
  lateCheckin30,        // Trễ trên 30 phút (không cộng)
  lastMinuteCancel,     // Hủy sát giờ (< 12 tiếng)
  noShow,               // Không đến, không báo
  reviewFiveStar,       // Host đánh giá 5 sao
  reviewGoodStar,       // Host đánh giá 3-4 sao
  reviewBadStar,        // Host đánh giá < 3 sao
}

extension TrustLogReasonExt on TrustLogReason {
  String get label {
    switch (this) {
      case TrustLogReason.onTimeCheckin:
        return 'Check-in đúng giờ';
      case TrustLogReason.lateCheckin15:
        return 'Check-in trễ dưới 15 phút';
      case TrustLogReason.lateCheckin30:
        return 'Check-in trễ trên 30 phút';
      case TrustLogReason.lastMinuteCancel:
        return 'Hủy sát giờ (< 12 tiếng)';
      case TrustLogReason.noShow:
        return 'Vắng mặt không báo trước';
      case TrustLogReason.reviewFiveStar:
        return 'Host đánh giá 5 sao ⭐⭐⭐⭐⭐';
      case TrustLogReason.reviewGoodStar:
        return 'Host đánh giá 3-4 sao';
      case TrustLogReason.reviewBadStar:
        return 'Host đánh giá dưới 3 sao';
    }
  }

  int get delta {
    switch (this) {
      case TrustLogReason.onTimeCheckin:
        return 5;
      case TrustLogReason.lateCheckin15:
        return 2;
      case TrustLogReason.lateCheckin30:
        return 0;
      case TrustLogReason.lastMinuteCancel:
        return -5;
      case TrustLogReason.noShow:
        return -15;
      case TrustLogReason.reviewFiveStar:
        return 5;
      case TrustLogReason.reviewGoodStar:
        return 2;
      case TrustLogReason.reviewBadStar:
        return -3;
    }
  }
}

/// Một dòng lịch sử thay đổi điểm
class TrustEventLog {
  const TrustEventLog({
    required this.id,
    required this.reason,
    required this.delta,
    required this.timestamp,
    required this.eventName,
  });

  final String id;
  final TrustLogReason reason;
  final int delta;         // Thực tế cộng/trừ (có thể = 0)
  final DateTime timestamp;
  final String eventName;

  bool get isPositive => delta > 0;
  bool get isNegative => delta < 0;
}
