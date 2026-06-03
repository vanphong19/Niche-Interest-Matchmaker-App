import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../injection/injection_container.dart';
import '../../../../router/app_router.gr.dart';
import '../bloc/finder_cubit.dart';
import '../bloc/finder_state.dart';
import '../models/finder_ui_mappers.dart';
import '../widgets/finder_action_button.dart';
import '../widgets/finder_glass_panel.dart';
import '../widgets/finder_participant_avatar.dart';
import '../widgets/finder_radar_canvas.dart';
import '../widgets/finder_scaffold.dart';

@RoutePage()
class FinderWaitingPage extends StatelessWidget {
  const FinderWaitingPage({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FinderCubit>()..waitForRequest(requestId),
      child: BlocConsumer<FinderCubit, FinderState>(
        listener: (context, state) {
          final sessionId = state.session?.sessionId;
          if (state.status == FinderFlowStatus.active && sessionId != null) {
            context.router.replace(FinderRadarRoute(sessionId: sessionId));
          }
          if (state.status == FinderFlowStatus.requestDeclined ||
              state.status == FinderFlowStatus.requestExpired ||
              state.status == FinderFlowStatus.requestCancelled) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_waitingStatusMessage(state.status))),
            );
            context.router.maybePop();
          }
        },
        builder: (context, state) {
          final participant = state.partner == null
              ? null
              : participantToUi(state.partner!);
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
                  if (participant != null)
                    FinderRadarCanvas(
                      participant: participant,
                      currentUserAvatarUrl: '',
                      size: 250,
                      showLabel: false,
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  FinderGlassPanel(
                    child: Column(
                      children: [
                        if (participant != null)
                          FinderParticipantAvatar(
                            imageUrl: participant.avatarUrl,
                            name: participant.name,
                            pulsing: true,
                            accentColor: participant.accentColor,
                          ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          participant == null
                              ? 'Waiting for response...'
                              : 'Waiting for ${participant.name} to accept...',
                          style: AppTextStyles.headingMedium.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Location sharing starts only after they accept this request.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (state.request != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          _RequestExpiryCountdown(
                            expiresAt: state.request!.expiresAt,
                            onExpired: () => context
                                .read<FinderCubit>()
                                .markRequestExpiredLocally(requestId),
                          ),
                        ],
                        if (state.errorMessage != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            state.errorMessage!,
                            style: TextStyle(color: colorScheme.error),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        FinderActionButton(
                          label: 'Cancel Request',
                          secondary: true,
                          onPressed:
                              state.status == FinderFlowStatus.requestPending
                              ? () => context.read<FinderCubit>().cancelRequest(
                                  requestId,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

String _waitingStatusMessage(FinderFlowStatus status) {
  switch (status) {
    case FinderFlowStatus.requestDeclined:
      return 'Finder request declined.';
    case FinderFlowStatus.requestExpired:
      return 'Finder request expired.';
    case FinderFlowStatus.requestCancelled:
      return 'Finder request cancelled.';
    default:
      return 'Finder request ended.';
  }
}

class _RequestExpiryCountdown extends StatefulWidget {
  const _RequestExpiryCountdown({
    required this.expiresAt,
    required this.onExpired,
  });

  final DateTime expiresAt;
  final VoidCallback onExpired;

  @override
  State<_RequestExpiryCountdown> createState() =>
      _RequestExpiryCountdownState();
}

class _RequestExpiryCountdownState extends State<_RequestExpiryCountdown> {
  Timer? _timer;
  bool _notifiedExpired = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    WidgetsBinding.instance.addPostFrameCallback((_) => _tick());
  }

  @override
  void didUpdateWidget(covariant _RequestExpiryCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) {
      _notifiedExpired = false;
      if (mounted) setState(() {});
    }
  }

  void _tick() {
    if (!mounted) return;
    final expired = DateTime.now().isAfter(widget.expiresAt);
    if (expired && !_notifiedExpired) {
      _notifiedExpired = true;
      widget.onExpired();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final remaining = widget.expiresAt.difference(DateTime.now());
    final seconds = remaining.inSeconds;
    final expired = seconds <= 0;
    final label = expired
        ? 'Request expired'
        : 'Request expires in ${seconds.clamp(0, 999)}s';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: (expired ? colorScheme.error : colorScheme.primary).withValues(
          alpha: 0.10,
        ),
        borderRadius: AppSpacing.borderRadiusPill,
      ),
      child: Text(
        label,
        style: AppTextStyles.captionMedium.copyWith(
          color: expired ? colorScheme.error : colorScheme.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
