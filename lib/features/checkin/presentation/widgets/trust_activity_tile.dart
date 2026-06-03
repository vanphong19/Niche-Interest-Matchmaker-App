import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_localizations.dart';
import '../models/checkin_ui_model.dart';
import 'glass_card.dart';
import 'status_pill.dart';

class TrustActivityTile extends StatelessWidget {
  const TrustActivityTile({super.key, required this.item});

  final TrustActivityItem item;

  @override
  Widget build(BuildContext context) {
    final color = checkinToneColor(item.tone);
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Icon(item.icon, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.bodyMediumSemiBold.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.subtitle,
                  style: AppTextStyles.captionMedium.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusPill(label: _localizedStatus(item.status), tone: item.tone),
              const SizedBox(height: AppSpacing.xs),
              Text(
                item.points,
                style: AppTextStyles.captionSmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _localizedStatus(String value) {
    return switch (value) {
      'Arrived' => AppLocalizations.tr('checkin_status_arrived'),
      'Late Risk' => AppLocalizations.tr('checkin_status_late_risk'),
      'No-show' => AppLocalizations.tr('checkin_status_no_show'),
      _ => value,
    };
  }
}
