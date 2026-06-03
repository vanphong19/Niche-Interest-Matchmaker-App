import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../models/checkin_ui_model.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.icon,
    this.tone = CheckinStatusTone.neutral,
  });

  final String label;
  final IconData? icon;
  final CheckinStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(tone);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.26)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

Color checkinToneColor(CheckinStatusTone tone) => _toneColor(tone);

Color _toneColor(CheckinStatusTone tone) {
  switch (tone) {
    case CheckinStatusTone.success:
      return AppColors.success;
    case CheckinStatusTone.warning:
      return AppColors.warning;
    case CheckinStatusTone.error:
      return AppColors.error;
    case CheckinStatusTone.neutral:
      return AppColors.primary;
  }
}
