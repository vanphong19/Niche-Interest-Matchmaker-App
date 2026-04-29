import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class MatchedUserAvatar extends StatelessWidget {
  const MatchedUserAvatar({
    super.key,
    required this.imageUrl,
    this.size = 64,
    this.badgeText,
    this.badgeColor = AppColors.secondary,
    this.borderWidth = 3,
  });

  final String imageUrl;
  final double size;
  final String? badgeText;
  final Color badgeColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final badgeSize = size * 0.34;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.bgPrimary,
                  width: borderWidth,
                ),
                boxShadow: AppSpacing.shadowLarge,
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          if (badgeText != null)
            Positioned(
              right: -3,
              bottom: -3,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: size * 0.08,
                  vertical: size * 0.025,
                ),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  border: Border.all(color: AppColors.bgPrimary, width: 2),
                ),
                constraints: BoxConstraints(minWidth: badgeSize),
                child: Center(
                  child: Text(
                    badgeText!,
                    style: AppTextStyles.captionSmall.copyWith(
                      color: AppColors.textInverse,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
