// lib/features/trust/presentation/widgets/trust_badge_chip.dart
import 'package:flutter/material.dart';

import '../../domain/entities/trust_badge.dart';

/// Chip hiển thị một huy hiệu (earned hoặc locked)
class TrustBadgeChip extends StatelessWidget {
  const TrustBadgeChip({
    super.key,
    required this.badge,
    required this.isEarned,
    this.showTooltip = true,
  });

  final TrustBadge badge;
  final bool isEarned;
  final bool showTooltip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Widget chip = AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isEarned ? 1.0 : 0.45,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isEarned
              ? (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isEarned
                ? const Color(0xFF3B82F6).withValues(alpha: 0.25)
                : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: isEarned
              ? [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji + lock overlay
            Stack(
              alignment: Alignment.center,
              children: [
                ColorFiltered(
                  colorFilter: isEarned
                      ? const ColorFilter.mode(
                          Colors.transparent,
                          BlendMode.multiply,
                        )
                      : const ColorFilter.matrix([
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0,
                          0,
                          0,
                          1,
                          0,
                        ]),
                  child: Text(
                    badge.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                if (!isEarned)
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      size: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isEarned ? FontWeight.w700 : FontWeight.w500,
                color: isEarned
                    ? (isDark ? Colors.white : const Color(0xFF1C2C58))
                    : (isDark ? Colors.white38 : Colors.black38),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );

    if (!showTooltip) return chip;

    return Tooltip(
      message: isEarned ? '✅ ${badge.condition}' : '🔒 ${badge.condition}',
      preferBelow: true,
      child: chip,
    );
  }
}
