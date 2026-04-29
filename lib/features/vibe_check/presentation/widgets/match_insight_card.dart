import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'app_card.dart';

class MatchInsightCard extends StatelessWidget {
  const MatchInsightCard({
    super.key,
    required this.title,
    required this.description,
    required this.leadingIcon,
    required this.leadingBg,
    required this.leadingFg,
    required this.emphasisColor,
  });

  final String title;
  final String description;
  final IconData leadingIcon;
  final Color leadingBg;
  final Color leadingFg;
  final Color emphasisColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: leadingBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(leadingIcon, size: 18, color: leadingFg),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.headingSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            description,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: 3,
            width: 48,
            decoration: BoxDecoration(
              color: emphasisColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
          ),
        ],
      ),
    );
  }
}
