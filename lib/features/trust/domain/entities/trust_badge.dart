// lib/features/trust/domain/entities/trust_badge.dart

/// Các loại huy hiệu uy tín
enum TrustBadgeType {
  onTime,        // Người đúng hẹn
  activeHost,    // Chủ kèo năng nổ
  noNoShow,      // Không leo cây
  goldenCompanion, // Bạn đồng hành vàng
  committed,     // Người giữ kèo
}

class TrustBadge {
  const TrustBadge({
    required this.type,
    required this.emoji,
    required this.name,
    required this.description,
    required this.condition,
  });

  final TrustBadgeType type;
  final String emoji;
  final String name;
  final String description;   // Hiển thị ngắn
  final String condition;     // Điều kiện đầy đủ (tooltip)

  static const List<TrustBadge> all = [
    TrustBadge(
      type: TrustBadgeType.onTime,
      emoji: '🕐',
      name: 'Người đúng hẹn',
      description: 'Check-in đúng giờ ít nhất 5 lần',
      condition: 'Đã check-in đúng giờ (trước 15 phút) ít nhất 5 lần',
    ),
    TrustBadge(
      type: TrustBadgeType.activeHost,
      emoji: '🎯',
      name: 'Chủ kèo năng nổ',
      description: 'Tạo ít nhất 3 sự kiện thành công',
      condition: 'Đã tổ chức ít nhất 3 sự kiện được xác nhận hoàn thành',
    ),
    TrustBadge(
      type: TrustBadgeType.noNoShow,
      emoji: '🌿',
      name: 'Không leo cây',
      description: '30 ngày không có lần no-show',
      condition: 'Không có lần bỏ hẹn không báo trước trong 30 ngày gần nhất',
    ),
    TrustBadge(
      type: TrustBadgeType.goldenCompanion,
      emoji: '🌟',
      name: 'Bạn đồng hành vàng',
      description: 'Rating trung bình từ host >= 4.8',
      condition: 'Điểm đánh giá trung bình từ host đạt 4.8 sao trở lên',
    ),
    TrustBadge(
      type: TrustBadgeType.committed,
      emoji: '💪',
      name: 'Người giữ kèo',
      description: 'Tham gia ít nhất 10 sự kiện',
      condition: 'Đã tham gia và hoàn thành ít nhất 10 sự kiện',
    ),
  ];
}
