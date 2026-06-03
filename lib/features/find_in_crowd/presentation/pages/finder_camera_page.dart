import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../injection/injection_container.dart';
import '../../../../router/app_router.gr.dart';
import '../bloc/finder_cubit.dart';
import '../bloc/finder_state.dart';
import '../models/finder_ui_mappers.dart';
import '../widgets/finder_action_button.dart';
import '../widgets/finder_camera_overlay.dart';
import '../widgets/finder_map_background.dart';
import '../widgets/finder_scaffold.dart';

@RoutePage()
class FinderCameraPage extends StatelessWidget {
  const FinderCameraPage({super.key, required this.sessionId});

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
          final participant = state.partner == null
              ? null
              : participantToUi(
                  state.partner!,
                  distanceLabel: state.navigation?.distanceLabel ?? '--',
                  directionLabel:
                      state.navigation?.directionLabel ??
                      AppLocalizations.tr('finder_waiting_location'),
                );
          return FinderScaffold(
            title: AppLocalizations.tr('finder_visual_title'),
            subtitle: state.navigation == null
                ? AppLocalizations.tr('finder_gps_based_direction')
                : '${state.navigation!.distanceLabel} - ${AppLocalizations.tr('finder_approx_direction')}',
            extendBody: true,
            background: const FinderMapBackground(cameraMode: true),
            body: Stack(
              children: [
                if (participant != null)
                  FinderCameraOverlay(
                    participant: participant,
                    navigation: state.navigation,
                  ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 28,
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: FinderActionButton(
                                label: AppLocalizations.tr('finder_exit_ar'),
                                icon: Icons.arrow_back_rounded,
                                secondary: true,
                                onPressed: () => context.router.maybePop(),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: FinderActionButton(
                                label: AppLocalizations.tr('finder_stop_short'),
                                icon: Icons.stop_circle_rounded,
                                secondary: true,
                                destructive: true,
                                onPressed: () => context.router.push(
                                  FinderStopConfirmationRoute(
                                    sessionId: sessionId,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
