import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_localizations.dart';
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitFinderFlow(context);
      },
      child: FinderScaffold(
        title: AppLocalizations.tr('finder_ended_title'),
        subtitle: isExpired
            ? AppLocalizations.tr('finder_session_expired')
            : AppLocalizations.tr('finder_location_stopped'),
        showBack: false,
        background: const FinderMapBackground(dimmed: true),
        body: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: FinderConfirmationPanel(
              title: isExpired
                  ? AppLocalizations.tr('finder_session_expired_title')
                  : AppLocalizations.tr('finder_ended_panel_title'),
              message: AppLocalizations.tr('finder_ended_message'),
              primaryLabel: AppLocalizations.tr('done'),
              icon: Icons.check_circle_rounded,
              onPrimary: () => _exitFinderFlow(context),
            ),
          ),
        ),
        trailing: const Icon(
          Icons.verified_rounded,
          color: AppColors.success,
          size: 28,
        ),
      ),
    );
  }

  void _exitFinderFlow(BuildContext context) {
    context.router.popUntilRoot();
  }
}
