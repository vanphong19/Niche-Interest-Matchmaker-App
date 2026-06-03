// lib/features/trust/presentation/widgets/recovery_mission_card.dart
import 'package:flutter/material.dart';

import '../../domain/services/reputation_service.dart';

class _Mission {
  const _Mission({
    required this.emoji,
    required this.title,
    required this.reward,
    required this.progress,
    required this.total,
  });
  final String emoji;
  final String title;
  final int reward;
  final int progress;
  final int total;
}

/// Card hiển thị nhiệm vụ phục hồi điểm – chỉ hiện khi score < 60
class RecoveryMissionCard extends StatelessWidget {
  const RecoveryMissionCard({super.key, required this.score});

  final int score;

  static const List<_Mission> _missions = [
    _Mission(
      emoji: '✅',
      title: 'Tham gia & check-in đúng giờ 1 sự kiện',
      reward: 5,
      progress: 0,
      total: 1,
    ),
    _Mission(
      emoji: '⭐',
      title: 'Nhận đánh giá 5 sao từ host',
      reward: 5,
      progress: 0,
      total: 1,
    ),
    _Mission(
      emoji: '📅',
      title: 'Tham gia sự kiện liên tiếp 3 ngày',
      reward: 8,
      progress: 1,
      total: 3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (score >= 60) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final levelData = ReputationService.getLevel(score);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: levelData.color.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: levelData.color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  levelData.gradientColors.first.withValues(alpha: 0.15),
                  levelData.gradientColors.last.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: levelData.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Center(
                    child: Text('🎯', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nhiệm vụ phục hồi uy tín',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF1C2C58),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hoàn thành để tăng điểm nhanh',
                        style: TextStyle(
                          fontSize: 12,
                          color: levelData.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Missions list
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _missions.map((m) => _MissionRow(
                mission: m,
                accentColor: levelData.color,
                isDark: isDark,
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionRow extends StatelessWidget {
  const _MissionRow({
    required this.mission,
    required this.accentColor,
    required this.isDark,
  });

  final _Mission mission;
  final Color accentColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final progress = mission.progress / mission.total;
    final isDone = mission.progress >= mission.total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(mission.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mission.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDone
                        ? (isDark ? Colors.white54 : Colors.black38)
                        : (isDark ? Colors.white : const Color(0xFF1C2C58)),
                    decoration: isDone
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFF22C55E).withValues(alpha: 0.12)
                      : accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isDone ? '✓ Done' : '+${mission.reward} điểm',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isDone ? const Color(0xFF22C55E) : accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(
                isDone ? const Color(0xFF22C55E) : accentColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${mission.progress}/${mission.total}',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white38 : Colors.black38,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
