import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_localizations.dart';
import 'app_card.dart';
import 'item_tile.dart';

enum MatchProfileFlag { reliable, newcomer, lateRisk }

class MatchProfileData {
  const MatchProfileData({
    required this.name,
    required this.age,
    required this.distanceMiles,
    required this.matchPercent,
    required this.bio,
    required this.imageUrl,
    required this.interests,
    this.hasSharedTag = false,
    this.flag,
  });

  final String name;
  final int age;
  final int distanceMiles;
  final int matchPercent;
  final String bio;
  final String imageUrl;
  final List<String> interests;
  final bool hasSharedTag;
  final MatchProfileFlag? flag;
}

class MatchProfileCard extends StatelessWidget {
  const MatchProfileCard({
    super.key,
    required this.profile,
    this.onView,
    this.onChat,
  });

  final MatchProfileData profile;
  final VoidCallback? onView;
  final VoidCallback? onChat;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ImageBlock(
            profile: profile,
            onView: onView,
            onChat: onChat,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  '${profile.name}, ${profile.age}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${profile.distanceMiles} ${AppLocalizations.tr('miles_short')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.captionLarge,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            profile.bio,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final interest in profile.interests)
                ItemTile(label: interest, compact: true),
              if (profile.hasSharedTag)
                ItemTile(
                  label: AppLocalizations.tr('shared'),
                  icon: Icons.star,
                  compact: true,
                  backgroundColor: AppColors.primarySurface,
                  textColor: AppColors.primary,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImageBlock extends StatelessWidget {
  const _ImageBlock({
    required this.profile,
    this.onView,
    this.onChat,
  });

  final MatchProfileData profile;
  final VoidCallback? onView;
  final VoidCallback? onChat;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 220;

            return Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    profile.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: AppSpacing.md,
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ItemTile(
                          label:
                              '${profile.matchPercent}% ${AppLocalizations.tr('match')}',
                          compact: true,
                          backgroundColor: profile.matchPercent >= 80
                              ? AppColors.primary
                              : AppColors.bgTertiary.withValues(alpha: 0.9),
                          textColor: profile.matchPercent >= 80
                              ? AppColors.textInverse
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (profile.flag != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(child: _flagChip(profile.flag!)),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: Row(
                    children: [
                      _circleAction(
                        icon: Icons.visibility,
                        onTap: onView,
                        tooltip: AppLocalizations.tr('view_profile'),
                        compact: isCompact,
                      ),
                      if (onChat != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        _circleAction(
                          icon: Icons.chat_bubble,
                          onTap: onChat,
                          tooltip: AppLocalizations.tr('message'),
                          filled: true,
                          compact: isCompact,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _flagChip(MatchProfileFlag flag) {
    switch (flag) {
      case MatchProfileFlag.reliable:
        return ItemTile(
          icon: Icons.verified,
          label: AppLocalizations.tr('reliable'),
          compact: true,
          backgroundColor: AppColors.bgPrimary.withValues(alpha: 0.92),
          textColor: AppColors.secondary,
        );
      case MatchProfileFlag.newcomer:
        return ItemTile(
          icon: Icons.new_releases,
          label: AppLocalizations.tr('new'),
          compact: true,
          backgroundColor: AppColors.bgPrimary.withValues(alpha: 0.92),
          textColor: AppColors.secondary,
        );
      case MatchProfileFlag.lateRisk:
        return ItemTile(
          icon: Icons.schedule,
          label: AppLocalizations.tr('late_risk'),
          compact: true,
          backgroundColor: AppColors.errorLight.withValues(alpha: 0.95),
          textColor: AppColors.error,
        );
    }
  }

  Widget _circleAction({
    required IconData icon,
    required VoidCallback? onTap,
    required String tooltip,
    bool filled = false,
    bool compact = false,
  }) {
    return Material(
      color: filled ? AppColors.primary : AppColors.bgPrimary,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
          child: Tooltip(
            message: tooltip,
            child: Icon(
              icon,
              color: filled ? AppColors.textInverse : AppColors.primary,
              size: compact ? 18 : 20,
            ),
          ),
        ),
      ),
    );
  }
}
