import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/avatar_widget.dart';

class VerificationAvatar extends StatelessWidget {
  const VerificationAvatar({
    super.key,
    required this.imageUrl,
    required this.name,
    this.size = 48,
    this.glow = false,
  });

  final String imageUrl;
  final String name;
  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(size * 0.04),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.45),
          width: 2,
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.32),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : AppSpacing.shadowSmall,
      ),
      child: VibeAvatar(
        imageUrl: imageUrl,
        name: name,
        size: size,
        showBorder: false,
      ),
    );
  }
}
