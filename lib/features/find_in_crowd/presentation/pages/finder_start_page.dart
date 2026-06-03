import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../injection/injection_container.dart';
import '../../../../router/app_router.gr.dart';
import '../bloc/finder_cubit.dart';
import '../bloc/finder_state.dart';
import '../models/finder_ui_mappers.dart';
import '../widgets/finder_current_location_card.dart';
import '../widgets/finder_map_background.dart';
import '../widgets/finder_panels.dart';
import '../widgets/finder_scaffold.dart';

@RoutePage()
class FinderStartPage extends StatelessWidget {
  const FinderStartPage({
    super.key,
    required this.eventId,
    required this.partnerId,
  });

  final String eventId;
  final String partnerId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<FinderCubit>()
            ..prepareStart(eventId: eventId, partnerId: partnerId),
      child: BlocConsumer<FinderCubit, FinderState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.request?.requestId != current.request?.requestId,
        listener: (context, state) {
          final requestId = state.request?.requestId;
          if (state.status == FinderFlowStatus.requestPending &&
              requestId != null) {
            context.router.replace(FinderWaitingRoute(requestId: requestId));
          }
        },
        builder: (context, state) {
          final cubit = context.read<FinderCubit>();
          final partner = state.partner;
          final participant = partner == null ? null : participantToUi(partner);
          final isLoading =
              state.status == FinderFlowStatus.requestCreating ||
              state.status == FinderFlowStatus.permissionRequired;

          return FinderScaffold(
            title: partner == null
                ? AppLocalizations.tr('finder_find_in_crowd')
                : '${AppLocalizations.tr('finder_find_question_prefix')} ${partner.firstName}',
            subtitle: AppLocalizations.tr('finder_temporary_live_location'),
            background: const FinderMapBackground(dimmed: true),
            body: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FinderCurrentLocationCard(
                      location: state.currentLocation,
                      isLoading: isLoading,
                      errorMessage: state.errorMessage,
                      onRequestLocation: cubit.refreshCurrentLocation,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (participant != null)
                      FinderStartPanel(
                        participant: participant,
                        onStart: isLoading
                            ? () {}
                            : () => cubit.sendRequest(
                                eventId: eventId,
                                partnerId: partnerId,
                              ),
                        onCancel: () => context.router.maybePop(),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
