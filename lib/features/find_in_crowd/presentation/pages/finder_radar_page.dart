import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../injection/injection_container.dart';
import '../../../../router/app_router.gr.dart';
import '../bloc/finder_cubit.dart';
import '../bloc/finder_state.dart';
import '../models/finder_ui_mappers.dart';
import '../widgets/finder_action_button.dart';
import '../widgets/finder_current_location_card.dart';
import '../widgets/finder_glass_panel.dart';
import '../widgets/finder_guidance_card.dart';
import '../widgets/finder_radar_canvas.dart';
import '../widgets/finder_scaffold.dart';
import '../widgets/finder_signal_card.dart';
import '../widgets/finder_status_pill.dart';

@RoutePage()
class FinderRadarPage extends StatelessWidget {
  const FinderRadarPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FinderCubit>()..startSession(sessionId),
      child: BlocConsumer<FinderCubit, FinderState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == FinderFlowStatus.ended) {
            context.router.replace(
              FinderEndedRoute(sessionId: sessionId, reason: state.endReason),
            );
          }
        },
        builder: (context, state) {
          final partner = state.partner;
          final participant = partner == null
              ? null
              : participantToUi(
                  partner,
                  distanceLabel: state.navigation?.distanceLabel ?? '--',
                  directionLabel: state.navigation?.directionLabel ?? 'Waiting',
                );
          final colorScheme = Theme.of(context).colorScheme;

          return FinderScaffold(
            title: partner == null ? 'Finding' : 'Finding ${partner.firstName}',
            subtitle:
                '${state.navigation?.distanceLabel ?? 'Live'} - ${state.navigation?.directionLabel ?? 'Waiting'}',
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                children: [
                  FinderStatusPill(
                    label: state.navigation == null
                        ? 'Waiting for shared location'
                        : '${state.navigation!.distanceLabel} away',
                    icon: Icons.navigation_rounded,
                    color: state.isVeryClose
                        ? AppColors.success
                        : colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (participant != null)
                    FinderRadarCanvas(
                      participant: participant,
                      currentUserAvatarUrl: '',
                      navigation: state.navigation,
                      size: 310,
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  FinderGuidanceCard(
                    navigation: state.navigation,
                    isStale: state.hasStalePartnerLocation,
                    weakGps: state.weakGps,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (participant != null)
                    FinderSignalCard(
                      participant: participant,
                      signalLabel: state.hasStalePartnerLocation
                          ? 'Reconnecting'
                          : (state.weakGps ? 'Weak GPS' : 'Live signal'),
                      accuracyLabel:
                          state.currentLocation?.accuracyLabel ?? 'Waiting',
                      distanceLabel: state.navigation?.distanceLabel,
                      directionLabel: state.navigation?.directionLabel,
                    ),
                  const SizedBox(height: AppSpacing.md),
                  FinderCurrentLocationCard(
                    location: state.currentLocation,
                    isLoading: false,
                    errorMessage: state.errorMessage,
                    onRequestLocation: () =>
                        context.read<FinderCubit>().refreshCurrentLocation(),
                    showAction: false,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FinderGlassPanel(
                    child: Row(
                      children: [
                        Icon(
                          state.isNearby
                              ? Icons.directions_walk_rounded
                              : Icons.gps_fixed_rounded,
                          color: state.isNearby
                              ? AppColors.success
                              : colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            state.hasStalePartnerLocation
                                ? 'Waiting for the latest partner location. Sharing resumes when both apps are active.'
                                : state.isNearby
                                ? 'Final guidance is available. Keep moving slowly and look around visually near the last few meters.'
                                : 'Live location sharing is active. Follow the direction card until you are close enough for final guidance.',
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
                    label: state.isNearby
                        ? 'Open Final Guidance'
                        : 'Final Guidance Unlocks Within 30m',
                    icon: state.isNearby
                        ? Icons.directions_walk_rounded
                        : Icons.social_distance_rounded,
                    onPressed: state.isNearby
                        ? () => context.router.push(
                            FinderNearbyRoute(sessionId: sessionId),
                          )
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FinderActionButton(
                    label: 'Stop Sharing',
                    icon: Icons.stop_circle_rounded,
                    secondary: true,
                    destructive: true,
                    onPressed: () => context.router.push(
                      FinderStopConfirmationRoute(sessionId: sessionId),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
