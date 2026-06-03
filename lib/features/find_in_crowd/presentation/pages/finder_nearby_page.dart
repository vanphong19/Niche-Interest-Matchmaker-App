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
import '../widgets/finder_glass_panel.dart';
import '../widgets/finder_guidance_card.dart';
import '../widgets/finder_participant_avatar.dart';
import '../widgets/finder_radar_canvas.dart';
import '../widgets/finder_scaffold.dart';
import '../widgets/finder_status_pill.dart';

@RoutePage()
class FinderNearbyPage extends StatelessWidget {
  const FinderNearbyPage({super.key, required this.sessionId});

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
                  distanceLabel: state.navigation?.distanceLabel ?? 'nearby',
                  directionLabel:
                      state.navigation?.directionLabel ?? 'toward marker',
                );
          final colorScheme = Theme.of(context).colorScheme;
          final distance = state.navigation?.distanceLabel ?? 'nearby';
          final isVeryClose = state.isVeryClose;

          return FinderScaffold(
            title: 'Nearby',
            subtitle: 'Final approach',
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                children: [
                  if (participant != null)
                    FinderRadarCanvas(
                      participant: participant,
                      currentUserAvatarUrl: '',
                      navigation: state.navigation,
                      size: 260,
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  FinderGuidanceCard(
                    navigation: state.navigation,
                    isStale: state.hasStalePartnerLocation,
                    weakGps: state.weakGps,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FinderGlassPanel(
                    radius: 30,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      children: [
                        if (participant != null)
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
                              ? '${partner?.firstName ?? 'They'} should be right around you.'
                              : state.navigation?.stepInstructionLabel ??
                                    '${partner?.firstName ?? 'They'} is close. Keep moving toward the marker.',
                          style: AppTextStyles.headingMedium.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          isVeryClose
                              ? 'Look around, wave, or message them. GPS can drift in the last few meters.'
                              : 'Distance updates live from GPS. Walk slowly so Finder can keep the arrow stable.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xl),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
