import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_localizations.dart';
import 'glass_card.dart';

class GpsStatusCard extends StatelessWidget {
  const GpsStatusCard({
    super.key,
    this.distance = '23m',
    this.compact = false,
  });

  final String distance;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        GlassCard(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.md : AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              _InfoChip(
                icon: Icons.check_circle_rounded,
                label: AppLocalizations.tr('checkin_gps_verified'),
                color: AppColors.success,
              ),
              Container(
                width: 1,
                height: 18,
                color: colorScheme.outline.withValues(alpha: 0.42),
              ),
              Text.rich(
                TextSpan(
                  text: '${AppLocalizations.tr('checkin_distance')}: ',
                  children: [
                    TextSpan(
                      text: distance,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                style: AppTextStyles.labelMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            AppLocalizations.tr('checkin_location_auto_verified'),
            style: AppTextStyles.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
