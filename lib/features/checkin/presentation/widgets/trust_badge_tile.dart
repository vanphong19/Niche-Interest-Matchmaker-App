import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_localizations.dart';
import '../models/checkin_ui_model.dart';
import 'glass_card.dart';
import 'status_pill.dart';

class TrustBadgeTile extends StatelessWidget {
  const TrustBadgeTile({super.key, required this.item});

  final TrustBadgeItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = item.locked
        ? colorScheme.onSurfaceVariant
        : checkinToneColor(item.tone);
    return SizedBox(
      width: 112,
      child: Opacity(
        opacity: item.locked ? 0.52 : 1,
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.14),
                ),
                child: Icon(item.icon, color: color, size: 30),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _localizedLabel(item.label),
                style: AppTextStyles.captionMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _localizedLabel(String value) {
    return switch (value) {
      'Early Bird' => AppLocalizations.tr('checkin_badge_early_bird'),
      'Reliable Host' => AppLocalizations.tr('checkin_badge_reliable_host'),
      'Explorer' => AppLocalizations.tr('checkin_badge_explorer'),
      'Top Guest' => AppLocalizations.tr('checkin_badge_top_guest'),
      _ => value,
    };
  }
}
