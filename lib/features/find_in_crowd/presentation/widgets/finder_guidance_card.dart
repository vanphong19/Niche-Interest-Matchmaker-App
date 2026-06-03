import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_localizations.dart';
import '../models/finder_location_ui_model.dart';
import 'finder_glass_panel.dart';

class FinderGuidanceCard extends StatelessWidget {
  const FinderGuidanceCard({
    super.key,
    required this.navigation,
    required this.isStale,
    required this.weakGps,
  });

  final FinderNavigationUiModel? navigation;
  final bool isStale;
  final bool weakGps;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentNavigation = navigation;
    final iconColor = isStale || weakGps
        ? colorScheme.tertiary
        : colorScheme.primary;
    final title = currentNavigation == null
        ? AppLocalizations.tr('finder_waiting_shared_location')
        : currentNavigation.stepInstructionLabel;
    final subtitle = currentNavigation == null
        ? AppLocalizations.tr('finder_guidance_keep_apps_open')
        : _subtitleFor(currentNavigation);

    return FinderGlassPanel(
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: currentNavigation == null
                ? Icon(
                    Icons.location_searching_rounded,
                    color: iconColor,
                    size: 34,
                  )
                : RotationTransition(
                    turns: AlwaysStoppedAnimation<double>(
                      currentNavigation.arrowTurns,
                    ),
                    child: Icon(
                      Icons.navigation_rounded,
                      color: iconColor,
                      size: 38,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTextStyles.captionMedium.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isStale || weakGps) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isStale
                        ? AppLocalizations.tr('finder_signal_stale')
                        : AppLocalizations.tr('finder_gps_weak_open_area'),
                    style: AppTextStyles.captionSmall.copyWith(
                      color: iconColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _subtitleFor(FinderNavigationUiModel navigation) {
    final direction = navigation.guidanceLabel;
    final accuracy = navigation.headingConfidenceLabel;
    return '$direction - ${navigation.distanceLabel} ${AppLocalizations.tr('finder_away')} - $accuracy';
  }
}
