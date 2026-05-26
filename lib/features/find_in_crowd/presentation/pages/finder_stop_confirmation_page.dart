import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../router/app_router.gr.dart';
import '../mock/finder_mock_data.dart';
import '../widgets/finder_map_background.dart';
import '../widgets/finder_panels.dart';
import '../widgets/finder_scaffold.dart';

@RoutePage()
class FinderStopConfirmationPage extends StatelessWidget {
  const FinderStopConfirmationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final participant = FinderMockData.session.partner;
    return FinderScaffold(
      title: 'Stop Finding',
      subtitle: participant.fullName,
      background: const FinderMapBackground(dimmed: true),
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: FinderConfirmationPanel(
            title: 'End finder session?',
            message:
                'Temporary location sharing with ${participant.name} will stop and this finder session will be closed.',
            primaryLabel: 'End Session',
            secondaryLabel: 'Continue',
            icon: Icons.location_off_rounded,
            destructive: true,
            onPrimary: () => context.router.replace(const FinderEndedRoute()),
            onSecondary: () => context.router.maybePop(),
          ),
        ),
      ),
    );
  }
}
