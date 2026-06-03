import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_localizations.dart';
import '../models/finder_participant_ui_model.dart';
import 'finder_glass_panel.dart';

class FinderSignalCard extends StatelessWidget {
  const FinderSignalCard({
    super.key,
    required this.participant,
    required this.signalLabel,
    required this.accuracyLabel,
    this.distanceLabel,
    this.directionLabel,
  });

  final FinderParticipantUiModel participant;
  final String signalLabel;
  final String accuracyLabel;
  final String? distanceLabel;
  final String? directionLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FinderGlassPanel(
      child: Row(
        children: [
          _SignalMetric(
            icon: Icons.near_me_rounded,
            label: AppLocalizations.tr('finder_distance'),
            value: distanceLabel ?? participant.distanceLabel,
          ),
          const SizedBox(width: AppSpacing.sm),
          _SignalMetric(
            icon: Icons.explore_rounded,
            label: AppLocalizations.tr('finder_direction'),
            value: directionLabel ?? participant.directionLabel,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.10),
                borderRadius: AppSpacing.borderRadiusLarge,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.signal_cellular_alt_rounded,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    signalLabel,
                    style: AppTextStyles.captionMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    accuracyLabel,
                    style: AppTextStyles.captionSmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalMetric extends StatelessWidget {
  const _SignalMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.30),
          borderRadius: AppSpacing.borderRadiusLarge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colorScheme.primary, size: 20),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: AppTextStyles.headingSmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.captionSmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
