import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../router/app_router.gr.dart';
import '../mock/finder_mock_data.dart';
import '../widgets/finder_action_button.dart';
import '../widgets/finder_camera_overlay.dart';
import '../widgets/finder_location_auto_updater.dart';
import '../widgets/finder_map_background.dart';
import '../widgets/finder_scaffold.dart';

@RoutePage()
class FinderCameraPage extends StatelessWidget {
  const FinderCameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    final participant = FinderMockData.session.partner;
    return FinderLocationAutoUpdater(
      child: FinderScaffold(
        title: 'Camera Finder',
        subtitle: 'Fake AR overlay',
        extendBody: true,
        background: const FinderMapBackground(cameraMode: true),
        body: Stack(
          children: [
            FinderCameraOverlay(participant: participant),
            Positioned(
              left: 20,
              right: 20,
              bottom: 28,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FinderActionButton(
                      label: 'Confirm Stop',
                      icon: Icons.location_off_rounded,
                      onPressed: () => context.router.push(
                        const FinderStopConfirmationRoute(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: FinderActionButton(
                            label: 'Call',
                            icon: Icons.call_rounded,
                            secondary: true,
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: FinderActionButton(
                            label: 'Exit',
                            icon: Icons.stop_circle_rounded,
                            secondary: true,
                            destructive: true,
                            onPressed: () => context.router.push(
                              const FinderStopConfirmationRoute(),
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
      ),
    );
  }
}
