import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../models/finder_location_ui_model.dart';
import '../models/finder_participant_ui_model.dart';
import 'finder_participant_avatar.dart';

class FinderCameraOverlay extends StatelessWidget {
  const FinderCameraOverlay({
    super.key,
    required this.participant,
    required this.navigation,
  });

  final FinderParticipantUiModel participant;
  final FinderNavigationUiModel? navigation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned(
          top: 130,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.82),
                  borderRadius: AppSpacing.borderRadiusPill,
                ),
                child: Text(
                  'AR-style Finder',
                  style: AppTextStyles.captionMedium.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 190,
          left: 48,
          right: 48,
          child: _TargetReticle(
            participant: participant,
            navigation: navigation,
          ),
        ),
        Positioned(
          top: 386,
          left: 24,
          right: 24,
          child: _DirectionArrow(
            directionLabel:
                navigation?.guidanceLabel ?? 'Waiting for shared location',
            compassLabel: navigation?.directionLabel,
            distanceLabel: navigation?.distanceLabel,
            detailLabel: navigation?.turnDetailLabel,
            arrowTurns: navigation?.arrowTurns,
          ),
        ),
        Positioned(
          bottom: 168,
          left: 24,
          right: 24,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.82),
              borderRadius: AppSpacing.borderRadiusLarge,
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.20),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.my_location_rounded, color: colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'GPS-based approximate direction to ${participant.name}. Keep scanning visually when you get close.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DirectionArrow extends StatelessWidget {
  const _DirectionArrow({
    required this.directionLabel,
    required this.compassLabel,
    required this.distanceLabel,
    required this.detailLabel,
    required this.arrowTurns,
  });

  final String directionLabel;
  final String? compassLabel;
  final String? distanceLabel;
  final String? detailLabel;
  final double? arrowTurns;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.88),
        borderRadius: AppSpacing.borderRadiusLarge,
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: arrowTurns == null
                ? Icon(
                    Icons.location_searching_rounded,
                    color: colorScheme.primary,
                    size: 34,
                  )
                : RotationTransition(
                    turns: AlwaysStoppedAnimation<double>(arrowTurns!),
                    child: Icon(
                      Icons.navigation_rounded,
                      color: colorScheme.primary,
                      size: 36,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  directionLabel,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  distanceLabel == null || compassLabel == null
                      ? 'No target position yet'
                      : '$distanceLabel - $compassLabel',
                  style: AppTextStyles.captionMedium.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (detailLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    detailLabel!,
                    style: AppTextStyles.captionMedium.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetReticle extends StatelessWidget {
  const _TargetReticle({required this.participant, required this.navigation});

  final FinderParticipantUiModel participant;
  final FinderNavigationUiModel? navigation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.success, width: 2),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.42),
                  ),
                ),
              ),
              FinderParticipantAvatar(
                imageUrl: participant.avatarUrl,
                name: participant.name,
                size: 70,
                pulsing: true,
                accentColor: AppColors.success,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.88),
            borderRadius: AppSpacing.borderRadiusPill,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                participant.name,
                style: AppTextStyles.labelLarge.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                navigation?.distanceLabel ?? 'waiting',
                style: AppTextStyles.labelMedium.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
