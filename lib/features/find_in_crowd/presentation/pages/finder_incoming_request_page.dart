import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../router/app_router.gr.dart';
import '../mock/finder_mock_data.dart';
import '../widgets/finder_map_background.dart';
import '../widgets/finder_panels.dart';
import '../widgets/finder_scaffold.dart';

@RoutePage()
class FinderIncomingRequestPage extends StatelessWidget {
  const FinderIncomingRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FinderScaffold(
      title: 'Finder Request',
      subtitle: FinderMockData.phong.fullName,
      background: const FinderMapBackground(dimmed: true),
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: FinderRequestPanel(
            participant: FinderMockData.phong,
            onAccept: () => context.router.replace(const FinderRadarRoute()),
            onDecline: () => context.router.maybePop(),
          ),
        ),
      ),
    );
  }
}
