import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_localizations.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({
    super.key,
    required this.title,
    required this.onSettingsPressed,
  });

  final String title;
  final VoidCallback onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth <= 360;

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xxl),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? AppSpacing.md : AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.bgPrimary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
            boxShadow: AppSpacing.shadowLarge,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
                    ),
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: isCompact ? 18 : 20,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: onSettingsPressed,
                icon: const Icon(Icons.tune, size: 20),
                tooltip: AppLocalizations.tr('settings'),
              ),
            ],
          ),
        );
      },
    );
  }
}
