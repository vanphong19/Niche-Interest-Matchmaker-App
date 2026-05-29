// lib/features/trust/presentation/widgets/user_trust_card.dart
import 'package:flutter/material.dart';

import '../../domain/entities/user_trust.dart';
import '../../domain/services/reputation_service.dart';

/// Card compact hiển thị uy tín của user – dùng trong ManageEventPage
class UserTrustCard extends StatefulWidget {
  const UserTrustCard({
    super.key,
    required this.trust,
    this.showWarning = true,
  });

  final UserTrust trust;
  final bool showWarning;

  @override
  State<UserTrustCard> createState() => _UserTrustCardState();
}

class _UserTrustCardState extends State<UserTrustCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final levelData = ReputationService.getLevel(widget.trust.score);
    final isLowTrust = widget.trust.score < 40;
    final isRestricted = widget.trust.isRestricted;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: isLowTrust
              ? (isDark
                  ? const Color(0xFF2A1A1A)
                  : const Color(0xFFFFF5F5))
              : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFFF8FAFF)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLowTrust
                ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                : levelData.color.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // ─── Summary Row ─────────────────────────────────────────────────
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    // Score badge
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: levelData.gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${widget.trust.score}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'pts',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Level + stats mini
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                levelData.emoji,
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                levelData.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: levelData.color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _MiniStat(
                                icon: Icons.check_circle_outline_rounded,
                                value: '${(widget.trust.attendanceRate * 100).round()}%',
                                label: 'tham gia',
                                color: const Color(0xFF22C55E),
                              ),
                              const SizedBox(width: 12),
                              _MiniStat(
                                icon: Icons.warning_amber_rounded,
                                value: '${ReputationService.getNoShowsLast30Days(widget.trust.history)}',
                                label: 'leo cây/30d',
                                color: const Color(0xFFEF4444),
                              ),
                              const SizedBox(width: 12),
                              _MiniStat(
                                icon: Icons.star_rounded,
                                value: widget.trust.avgHostRating.toStringAsFixed(1),
                                label: 'rating',
                                color: const Color(0xFFF59E0B),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Expand chevron
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: isDark ? Colors.white38 : Colors.black26,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            // ─── Expanded Detail ─────────────────────────────────────────────
            if (_expanded) ...[
              Divider(
                height: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _DetailStat(
                          label: 'Sự kiện\ntham gia',
                          value: '${widget.trust.eventsJoined}',
                          isDark: isDark,
                        ),
                        _DetailStat(
                          label: 'Check-in\nđúng giờ',
                          value: '${widget.trust.onTimeCheckins}',
                          isDark: isDark,
                        ),
                        _DetailStat(
                          label: 'Hủy\nsát giờ',
                          value: '${widget.trust.lastMinuteCancels}',
                          isDark: isDark,
                        ),
                      ],
                    ),

                    // Warning
                    if (widget.showWarning && (isLowTrust || isRestricted)) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                const Color(0xFFEF4444).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFEF4444),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isRestricted
                                    ? 'Người dùng này đang bị hạn chế do leo cây nhiều lần.'
                                    : 'Điểm uy tín thấp (<40). Cân nhắc trước khi chấp nhận.',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(
          '$value $label',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class _DetailStat extends StatelessWidget {
  const _DetailStat({
    required this.label,
    required this.value,
    required this.isDark,
  });
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF1C2C58),
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
