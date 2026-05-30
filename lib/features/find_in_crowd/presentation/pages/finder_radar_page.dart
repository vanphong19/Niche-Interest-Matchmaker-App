import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../router/app_router.gr.dart';
import '../finder_location_session.dart';
import '../mock/finder_mock_data.dart';
import '../widgets/finder_action_button.dart';
import '../widgets/finder_current_location_card.dart';
import '../widgets/finder_glass_panel.dart';
import '../widgets/finder_location_auto_updater.dart';
import '../widgets/finder_radar_canvas.dart';
import '../widgets/finder_scaffold.dart';
import '../widgets/finder_signal_card.dart';
import '../widgets/finder_status_pill.dart';

@RoutePage()
class FinderRadarPage extends StatelessWidget {
  const FinderRadarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = FinderMockData.session;
    final participant = session.partner;
    final colorScheme = Theme.of(context).colorScheme;

    return FinderLocationAutoUpdater(
      child: FinderScaffold(
        title: 'Searching for ${participant.name}',
        subtitle:
            '${participant.distanceLabel} - ${participant.directionLabel}',
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            children: [
              ValueListenableBuilder(
                valueListenable: FinderLocationSession.currentLocation,
                builder: (context, location, _) {
                  final navigation = FinderLocationSession.navigationFrom(
                    location,
                  );
                  return FinderStatusPill(
                    label:
                        '${navigation?.distanceLabel ?? participant.distanceLabel} away',
                    icon: Icons.navigation_rounded,
                    color: navigation?.isVeryClose == true
                        ? AppColors.success
                        : colorScheme.primary,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              ValueListenableBuilder(
                valueListenable: FinderLocationSession.currentLocation,
                builder: (context, location, _) {
                  final navigation = FinderLocationSession.navigationFrom(
                    location,
                  );
                  return FinderRadarCanvas(
                    participant: participant,
                    currentUserAvatarUrl: FinderMockData.currentUserAvatar,
                    navigation: navigation,
                    size: 310,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              ValueListenableBuilder(
                valueListenable: FinderLocationSession.currentLocation,
                builder: (context, location, _) {
                  final navigation = FinderLocationSession.navigationFrom(
                    location,
                  );
                  return FinderSignalCard(
                    participant: participant,
                    signalLabel: navigation?.isVeryClose == true
                        ? 'Very close'
                        : session.signalLabel,
                    accuracyLabel:
                        location?.accuracyLabel ?? session.accuracyLabel,
                    distanceLabel: navigation?.distanceLabel,
                    directionLabel: navigation?.directionLabel,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              ValueListenableBuilder(
                valueListenable: FinderLocationSession.currentLocation,
                builder: (context, location, _) {
                  return FinderCurrentLocationCard(
                    location: location,
                    isLoading: false,
                    onRequestLocation: () {},
                    showAction: false,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              FinderGlassPanel(
                child: Row(
                  children: [
                    const Icon(Icons.shield_rounded, color: AppColors.success),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'GPS updates automatically while this finder screen is open. Sharing ends when you stop finding.',
                        style: AppTextStyles.captionMedium.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FinderActionButton(
                label: 'Move Closer',
                icon: Icons.social_distance_rounded,
                onPressed: () => context.router.push(const FinderNearbyRoute()),
              ),
              const SizedBox(height: AppSpacing.sm),
              FinderActionButton(
                label: 'Stop',
                icon: Icons.stop_circle_rounded,
                secondary: true,
                destructive: true,
                onPressed: () =>
                    context.router.push(const FinderStopConfirmationRoute()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
