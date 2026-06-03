import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_localizations.dart';
import '../models/finder_location_ui_model.dart';
import 'finder_action_button.dart';
import 'finder_glass_panel.dart';
import 'finder_status_pill.dart';

class FinderCurrentLocationCard extends StatelessWidget {
  const FinderCurrentLocationCard({
    super.key,
    required this.location,
    required this.isLoading,
    required this.onRequestLocation,
    this.errorMessage,
    this.showAction = true,
  });

  final FinderLocationUiModel? location;
  final bool isLoading;
  final VoidCallback onRequestLocation;
  final String? errorMessage;
  final bool showAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasLocation = location != null;

    return FinderGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (hasLocation ? AppColors.success : colorScheme.primary)
                      .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasLocation
                      ? Icons.my_location_rounded
                      : Icons.location_searching_rounded,
                  color: hasLocation ? AppColors.success : colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasLocation
                          ? AppLocalizations.tr('finder_current_gps_position')
                          : AppLocalizations.tr(
                              'finder_gps_permission_required',
                            ),
                      style: AppTextStyles.bodyMediumSemiBold.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasLocation
                          ? location!.coordinateLabel
                          : AppLocalizations.tr('finder_allow_location_start'),
                      style: AppTextStyles.captionMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasLocation)
                FinderStatusPill(
                  label: location!.accuracyLabel,
                  icon: Icons.gps_fixed_rounded,
                  color: AppColors.success,
                ),
            ],
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.10),
                borderRadius: AppSpacing.borderRadiusMedium,
              ),
              child: Text(
                errorMessage!,
                style: AppTextStyles.captionMedium.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          if (showAction) ...[
            const SizedBox(height: AppSpacing.md),
            FinderActionButton(
              label: isLoading
                  ? AppLocalizations.tr('finder_getting_location')
                  : (hasLocation
                        ? AppLocalizations.tr('finder_refresh_gps')
                        : AppLocalizations.tr('finder_allow_gps_access')),
              icon: hasLocation
                  ? Icons.refresh_rounded
                  : Icons.gps_fixed_rounded,
              secondary: hasLocation,
              onPressed: isLoading ? null : onRequestLocation,
            ),
          ],
        ],
      ),
    );
  }
}
