import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'app_card.dart';
import 'matched_user_avatar.dart';

class GroupVibeMemberCard extends StatelessWidget {
  const GroupVibeMemberCard({
    super.key,
    required this.header,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.imageUrl,
  });

  final String header;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  header,
                  style: AppTextStyles.captionMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              MatchedUserAvatar(imageUrl: imageUrl, size: 40, borderWidth: 2),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMediumSemiBold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: AppTextStyles.captionLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
