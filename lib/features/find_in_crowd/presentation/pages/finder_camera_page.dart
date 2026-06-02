import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
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
      child: BlocBuilder<FinderCubit, FinderState>(
        builder: (context, state) {
          final participant = state.partner == null
              ? null
              : participantToUi(
                  state.partner!,
                  distanceLabel: state.navigation?.distanceLabel ?? '--',
                  directionLabel: state.navigation?.directionLabel ?? 'Waiting',
                );
          return FinderScaffold(
            title: 'AR-style Finder',
            subtitle: state.navigation == null
                ? 'GPS-based direction'
                : '${state.navigation!.distanceLabel} - approximate direction',
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
                                label: 'Exit AR',
                                icon: Icons.arrow_back_rounded,
                                secondary: true,
                                onPressed: () => context.router.maybePop(),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: FinderActionButton(
                                label: 'Stop',
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
