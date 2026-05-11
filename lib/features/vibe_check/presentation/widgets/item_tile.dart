import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class ItemTile extends StatelessWidget {
  const ItemTile({
    super.key,
    this.icon,
    required this.label,
    this.highlighted = false,
    this.backgroundColor,
    this.textColor,
    this.compact = false,
  });

  final IconData? icon;
  final String label;
  final bool highlighted;
  final Color? backgroundColor;
  final Color? textColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bgColor =
        backgroundColor ??
        (highlighted ? AppColors.successLight : AppColors.bgTertiary);
    final foregroundColor =
        textColor ??
        (highlighted ? AppColors.secondary : AppColors.textSecondary);
    final verticalPadding = compact ? AppSpacing.xs : AppSpacing.sm;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxChipWidth = math.min(screenWidth * 0.62, 220.0);

    return Container(
      constraints: BoxConstraints(maxWidth: maxChipWidth),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 14 : 18, color: foregroundColor),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: AppTextStyles.chipText.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 12 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
