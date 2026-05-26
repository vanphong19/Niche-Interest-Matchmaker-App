import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../router/app_router.gr.dart';
import '../mock/finder_mock_data.dart';
import '../widgets/finder_action_button.dart';
import '../widgets/finder_glass_panel.dart';
import '../widgets/finder_participant_avatar.dart';
import '../widgets/finder_radar_canvas.dart';
import '../widgets/finder_scaffold.dart';

@RoutePage()
class FinderWaitingPage extends StatelessWidget {
  const FinderWaitingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final participant = FinderMockData.session.partner;
    final colorScheme = Theme.of(context).colorScheme;

    return FinderScaffold(
      title: 'Waiting',
      subtitle: 'Request sent',
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.lg),
            FinderRadarCanvas(
              participant: participant,
              currentUserAvatarUrl: FinderMockData.currentUserAvatar,
              size: 250,
              showLabel: false,
            ),
            const SizedBox(height: AppSpacing.lg),
            FinderGlassPanel(
              child: Column(
                children: [
                  FinderParticipantAvatar(
                    imageUrl: participant.avatarUrl,
                    name: participant.name,
                    pulsing: true,
                    accentColor: participant.accentColor,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Waiting for ${participant.name} to accept...',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${participant.name} will receive a request to share approximate location for this meetup only.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FinderActionButton(
                    label: 'Open Receiver Request',
                    icon: Icons.person_search_rounded,
                    onPressed: () =>
                        context.router.push(const FinderIncomingRequestRoute()),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FinderActionButton(
                    label: 'Cancel Request',
                    secondary: true,
                    onPressed: () => context.router.popUntilRouteWithName(
                      FindInCrowdMeetingRoute.name,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
