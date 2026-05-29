import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../router/app_router.gr.dart';
import '../mock/finder_mock_data.dart';
import '../widgets/finder_map_background.dart';
import '../widgets/finder_panels.dart';
import '../widgets/finder_scaffold.dart';

@RoutePage()
class FinderEndedPage extends StatelessWidget {
  const FinderEndedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final participant = FinderMockData.session.partner;
    return FinderScaffold(
      title: 'Finder Ended',
      subtitle: participant.fullName,
      background: const FinderMapBackground(dimmed: true),
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: FinderConfirmationPanel(
            title: 'Search ended',
            message:
                'Your temporary location is no longer shared with ${participant.name}. Hope you found each other nearby.',
            primaryLabel: 'Back to Meeting',
            secondaryLabel: 'Find Again',
            icon: Icons.check_circle_rounded,
            onPrimary: () =>
                context.router.replaceAll([const FindInCrowdMeetingRoute()]),
            onSecondary: () => context.router.replace(const FinderStartRoute()),
          ),
        ),
      ),
      trailing: const Icon(
        Icons.verified_rounded,
        color: AppColors.success,
        size: 28,
      ),
    );
  }
}
