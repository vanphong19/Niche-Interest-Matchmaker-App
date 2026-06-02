import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../injection/injection_container.dart';
import '../../../../router/app_router.gr.dart';
import '../bloc/finder_cubit.dart';
import '../bloc/finder_state.dart';
import '../models/finder_ui_mappers.dart';
import '../widgets/finder_map_background.dart';
import '../widgets/finder_panels.dart';
import '../widgets/finder_scaffold.dart';

@RoutePage()
class FinderIncomingRequestPage extends StatelessWidget {
  const FinderIncomingRequestPage({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FinderCubit>()..loadIncomingRequest(requestId),
      child: BlocConsumer<FinderCubit, FinderState>(
        listener: (context, state) {
          final sessionId = state.session?.sessionId;
          if (state.status == FinderFlowStatus.active && sessionId != null) {
            context.router.replace(FinderRadarRoute(sessionId: sessionId));
          }
          if (state.status == FinderFlowStatus.requestDeclined) {
            context.router.maybePop();
          }
          if (state.status == FinderFlowStatus.requestCancelled ||
              state.status == FinderFlowStatus.requestExpired) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.status == FinderFlowStatus.requestExpired
                      ? 'Finder request expired.'
                      : 'Finder request was cancelled.',
                ),
              ),
            );
            context.router.maybePop();
          }
        },
        builder: (context, state) {
          final requester = state.partner;
          return FinderScaffold(
            title: 'Finder Request',
            subtitle: requester?.fullName ?? 'Live location request',
            background: const FinderMapBackground(dimmed: true),
            body: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: requester == null
                    ? const CircularProgressIndicator()
                    : FinderRequestPanel(
                        participant: participantToUi(requester),
                        onAccept: () => context
                            .read<FinderCubit>()
                            .acceptRequest(requestId),
                        onDecline: () => context
                            .read<FinderCubit>()
                            .declineRequest(requestId),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
