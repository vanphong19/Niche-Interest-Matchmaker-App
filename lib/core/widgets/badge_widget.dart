// lib/core/widgets/badge_widget.dart
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum VibeBadgeSize { small, medium, large }

class VibeBadge extends StatelessWidget {
  const VibeBadge({
    super.key,
    required this.label,
    this.color,
    this.textColor,
    this.size = VibeBadgeSize.medium,
    this.icon,
  });

  final String label;
  final Color? color;
  final Color? textColor;
  final VibeBadgeSize size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? AppColors.primarySurface;
    final fgColor = textColor ?? AppColors.primary;

    final (padding, fontSize, iconSize) = switch (size) {
      VibeBadgeSize.small => (
          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          10.0,
          10.0,
        ),
      VibeBadgeSize.medium => (
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          11.0,
          12.0,
        ),
      VibeBadgeSize.large => (
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          13.0,
          14.0,
        ),
    };

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppSpacing.borderRadiusPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: fgColor),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: AppTextStyles.badgeText.copyWith(
              fontSize: fontSize,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}

class MatchScoreBadge extends StatelessWidget {
  const MatchScoreBadge({
    super.key,
    required this.score,
    this.size = VibeBadgeSize.medium,
  });

  final int score;
  final VibeBadgeSize size;

  Color get _backgroundColor {
    if (score >= 90) return AppColors.matchGold.withValues(alpha: 0.15);
    if (score >= 75) return AppColors.matchBlue.withValues(alpha: 0.12);
    return AppColors.matchGray.withValues(alpha: 0.12);
  }

  Color get _foregroundColor {
    if (score >= 90) return const Color(0xFFD4A017);
    if (score >= 75) return AppColors.primary;
    return AppColors.textSecondary;
  }

  IconData get _icon {
    if (score >= 90) return Icons.bolt_rounded;
    if (score >= 75) return Icons.bolt_rounded;
    return Icons.circle;
  }

  @override
  Widget build(BuildContext context) {
    final (padding, fontSize, iconSize) = switch (size) {
      VibeBadgeSize.small => (
          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          10.0,
          12.0,
        ),
      VibeBadgeSize.medium => (
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          12.0,
          14.0,
        ),
      VibeBadgeSize.large => (
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          14.0,
          16.0,
        ),
    };

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: AppSpacing.borderRadiusPill,
        border: score >= 90
            ? Border.all(
                color: _foregroundColor.withValues(alpha: 0.4),
                width: 1,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: iconSize, color: _foregroundColor),
          const SizedBox(width: 2),
          Text(
            '$score%',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: _foregroundColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
