import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../router/app_router.gr.dart';
import '../finder_location_session.dart';
import '../mock/finder_mock_data.dart';
import '../widgets/finder_action_button.dart';
import '../widgets/finder_glass_panel.dart';
import '../widgets/finder_location_auto_updater.dart';
import '../widgets/finder_participant_avatar.dart';
import '../widgets/finder_radar_canvas.dart';
import '../widgets/finder_scaffold.dart';
import '../widgets/finder_status_pill.dart';

@RoutePage()
class FinderNearbyPage extends StatelessWidget {
  const FinderNearbyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final participant = FinderMockData.session.partner;
    final colorScheme = Theme.of(context).colorScheme;

    return FinderLocationAutoUpdater(
      child: FinderScaffold(
        title: 'Nearby',
        subtitle: 'Final approach',
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            children: [
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
                    size: 260,
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
                  final distance = navigation?.distanceLabel ?? 'nearby';
                  final isVeryClose = navigation?.isVeryClose == true;

                  return FinderGlassPanel(
                    radius: 30,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      children: [
                        FinderParticipantAvatar(
                          imageUrl: participant.avatarUrl,
                          name: participant.name,
                          size: 84,
                          pulsing: true,
                          accentColor: AppColors.success,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FinderStatusPill(
                          label: isVeryClose
                              ? 'Very close - $distance'
                              : 'Nearby - $distance',
                          icon: Icons.circle,
                          color: AppColors.success,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          isVeryClose
                              ? '${participant.name} should be right around you.'
                              : '${participant.name} is close. Keep moving ${navigation?.directionLabel.toLowerCase() ?? 'toward the marker'}.',
                          style: AppTextStyles.headingMedium.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          isVeryClose
                              ? 'Look around, wave, or open AR Finder for the last few steps.'
                              : 'Distance updates live from GPS. Open AR Finder when you are ready for visual guidance.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        FinderActionButton(
                          label: 'Open AR Finder',
                          icon: Icons.view_in_ar_rounded,
                          onPressed: () =>
                              context.router.push(const FinderCameraRoute()),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FinderActionButton(
                          label: 'Call ${participant.name}',
                          icon: Icons.call_rounded,
                          secondary: true,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
