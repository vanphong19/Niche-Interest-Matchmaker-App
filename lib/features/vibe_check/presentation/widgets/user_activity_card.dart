import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'app_card.dart';

class UserActivityCard extends StatelessWidget {
  const UserActivityCard({
    super.key,
    required this.type,
    required this.title,
    required this.timeLabel,
    required this.icon,
    required this.accentColor,
  });

  final String type;
  final String title;
  final String timeLabel;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SizedBox(
        height: 110,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type,
              style: AppTextStyles.captionSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              style: AppTextStyles.headingSmall.copyWith(fontSize: 18),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    timeLabel,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(icon, color: accentColor, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
