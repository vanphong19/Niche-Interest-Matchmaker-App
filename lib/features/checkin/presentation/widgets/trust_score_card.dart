import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_localizations.dart';
import '../mock/checkin_mock_data.dart';
import 'glass_card.dart';
import 'verification_avatar.dart';

class TrustScoreCard extends StatelessWidget {
  const TrustScoreCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const VerificationAvatar(
            imageUrl: CheckinMockData.userAvatar,
            name: CheckinMockData.userName,
            size: 88,
            glow: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            CheckinMockData.userName,
            style: AppTextStyles.headingSmall.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            AppLocalizations.tr('checkin_reputation_level'),
            style: AppTextStyles.captionLarge.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppLocalizations.tr('checkin_trust_score'),
                style: AppTextStyles.labelMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text.rich(
                TextSpan(
                  text: '94',
                  children: [
                    TextSpan(
                      text: '/100',
                      style: AppTextStyles.headingSmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                style: AppTextStyles.displayLarge.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: LinearProgressIndicator(
              value: 0.94,
              minHeight: 14,
              backgroundColor: colorScheme.primaryContainer,
              valueColor: const AlwaysStoppedAnimation(AppColors.success),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.trending_up_rounded,
                color: AppColors.success,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  AppLocalizations.tr('checkin_top_percent'),
                  style: AppTextStyles.captionMedium.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
