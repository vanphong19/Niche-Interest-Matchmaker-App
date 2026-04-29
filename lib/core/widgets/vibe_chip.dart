// lib/core/widgets/vibe_chip.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class VibeChip extends StatelessWidget {
  const VibeChip({
    super.key,
    required this.label,
    this.icon,
    this.isSelected = false,
    this.onTap,
    this.color,
    this.selectedColor,
    this.textColor,
    this.selectedTextColor,
    this.showCheckmark = false,
    this.size = VibeChipSize.medium,
  });

  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? color;
  final Color? selectedColor;
  final Color? textColor;
  final Color? selectedTextColor;
  final bool showCheckmark;
  final VibeChipSize size;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.bgTertiary;
    final effectiveSelectedColor = selectedColor ?? AppColors.primarySurface;
    final effectiveTextColor = textColor ?? AppColors.textPrimary;
    final effectiveSelectedTextColor = selectedTextColor ?? AppColors.primary;

    final padding = switch (size) {
      VibeChipSize.small =>
        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      VibeChipSize.medium =>
        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      VibeChipSize.large =>
        const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    };

    final fontSize = switch (size) {
      VibeChipSize.small => 11.0,
      VibeChipSize.medium => 13.0,
      VibeChipSize.large => 15.0,
    };

    final iconSize = switch (size) {
      VibeChipSize.small => 14.0,
      VibeChipSize.medium => 16.0,
      VibeChipSize.large => 18.0,
    };

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      child: AnimatedContainer(
        duration: AppSpacing.animationFast,
        curve: Curves.easeInOut,
        padding: padding,
        decoration: BoxDecoration(
          color: isSelected ? effectiveSelectedColor : effectiveColor,
          borderRadius: AppSpacing.borderRadiusPill,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showCheckmark && isSelected) ...[
              Icon(
                Icons.check_rounded,
                size: iconSize,
                color: effectiveSelectedTextColor,
              ),
              SizedBox(width: size == VibeChipSize.small ? 4 : 6),
            ] else if (icon != null) ...[
              Icon(
                icon,
                size: iconSize,
                color: isSelected
                    ? effectiveSelectedTextColor
                    : effectiveTextColor,
              ),
              SizedBox(width: size == VibeChipSize.small ? 4 : 6),
            ],
            Text(
              label,
              style: AppTextStyles.chipText.copyWith(
                fontSize: fontSize,
                color: isSelected
                    ? effectiveSelectedTextColor
                    : effectiveTextColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum VibeChipSize { small, medium, large }
