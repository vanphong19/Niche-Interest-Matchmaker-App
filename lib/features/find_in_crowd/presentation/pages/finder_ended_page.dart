import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/finder_map_background.dart';
import '../widgets/finder_panels.dart';
import '../widgets/finder_scaffold.dart';

@RoutePage()
class FinderEndedPage extends StatelessWidget {
  const FinderEndedPage({super.key, required this.sessionId, this.reason});

  final String sessionId;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final isExpired = reason == 'expired';
    return FinderScaffold(
      title: 'Finder Ended',
      subtitle: isExpired ? 'Session expired' : 'Location sharing stopped',
      background: const FinderMapBackground(dimmed: true),
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: FinderConfirmationPanel(
            title: isExpired ? 'Finder session expired' : 'Finder ended',
            message:
                'Your temporary location is no longer shared for this finder session.',
            primaryLabel: 'Back',
            secondaryLabel: 'Close',
            icon: Icons.check_circle_rounded,
            onPrimary: () => context.router.popUntilRoot(),
            onSecondary: () => context.router.maybePop(),
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
