import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../injection/injection_container.dart';
import '../../../../router/app_router.gr.dart';
import '../bloc/finder_cubit.dart';
import '../bloc/finder_state.dart';
import '../widgets/finder_map_background.dart';
import '../widgets/finder_panels.dart';
import '../widgets/finder_scaffold.dart';

@RoutePage()
class FinderStopConfirmationPage extends StatelessWidget {
  const FinderStopConfirmationPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FinderCubit>()..startSession(sessionId),
      child: BlocConsumer<FinderCubit, FinderState>(
        listener: (context, state) {
          if (state.status == FinderFlowStatus.ended) {
            context.router.replace(
              FinderEndedRoute(sessionId: sessionId, reason: state.endReason),
            );
          }
        },
        builder: (context, state) {
          final name =
              state.partner?.firstName ??
              AppLocalizations.tr('finder_your_partner');
          return FinderScaffold(
            title: AppLocalizations.tr('finder_stop'),
            subtitle: state.partner?.fullName,
            background: const FinderMapBackground(dimmed: true),
            body: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: FinderConfirmationPanel(
                  title: AppLocalizations.tr('finder_stop_sharing_question'),
                  message:
                      '${AppLocalizations.tr('finder_stop_message_prefix')} $name.',
                  primaryLabel: state.status == FinderFlowStatus.stopping
                      ? AppLocalizations.tr('finder_stopping')
                      : AppLocalizations.tr('finder_stop_sharing'),
                  secondaryLabel: AppLocalizations.tr('finder_keep_finding'),
                  icon: Icons.location_off_rounded,
                  destructive: true,
                  onPrimary: () => context.read<FinderCubit>().stopSession(),
                  onSecondary: () => context.router.maybePop(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
