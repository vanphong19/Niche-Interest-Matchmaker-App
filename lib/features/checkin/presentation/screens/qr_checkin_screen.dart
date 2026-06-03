import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../injection/injection_container.dart';
import '../bloc/checkin_bloc.dart';
import '../bloc/checkin_event.dart';
import '../bloc/checkin_state.dart';
import '../models/checkin_event_details.dart';
import '../widgets/checkin_event_summary_card.dart';
import '../widgets/checkin_scaffold.dart';
import '../widgets/checkin_status_view.dart';
import '../widgets/gps_status_card.dart';
import '../widgets/qr_scanner_view.dart';
import '../pages/checkin_verifying_page.dart';

class QrCheckinScreen extends StatelessWidget {
  const QrCheckinScreen({super.key, this.matchId, this.eventDetails});

  final String? matchId;
  final CheckinEventDetails? eventDetails;

  @override
  Widget build(BuildContext context) {
    final details =
        eventDetails ?? CheckinEventDetails.fallback(matchId: matchId);
    return BlocProvider(
      create: (_) => sl<CheckinBloc>()
        ..add(
          CheckinEvent.qrCheckinRequested(
            matchId: details.matchId,
            startsAt: details.startsAt,
            endsAt: details.endsAt,
          ),
        ),
      child: _QrCheckinView(details: details),
    );
  }
}

class _QrCheckinView extends StatelessWidget {
  const _QrCheckinView({required this.details});

  final CheckinEventDetails details;

  @override
  Widget build(BuildContext context) {
    return CheckinScaffold(
      title: AppLocalizations.tr('checkin_qr_method'),
      leadingIcon: Icons.close_rounded,
      onLeadingPressed: () => Navigator.of(context).maybePop(),
      body: BlocListener<CheckinBloc, CheckinState>(
        listenWhen: (previous, current) =>
            previous.qrStatus != current.qrStatus,
        listener: (context, state) {
          switch (state.qrStatus) {
            case QrCheckinStatus.success:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => CheckinVerifyingPage(
                    method: AppLocalizations.tr('checkin_qr_method'),
                    result: state.result,
                    eventDetails: details,
                  ),
                ),
              );
            case QrCheckinStatus.permissionDenied:
            case QrCheckinStatus.failure:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.errorMessage ??
                        AppLocalizations.tr('checkin_qr_failed'),
                  ),
                ),
              );
            case QrCheckinStatus.initial:
            case QrCheckinStatus.requestingPermission:
            case QrCheckinStatus.scanning:
              break;
          }
        },
        child: BlocBuilder<CheckinBloc, CheckinState>(
          builder: (context, state) {
            switch (state.qrStatus) {
              case QrCheckinStatus.initial:
              case QrCheckinStatus.requestingPermission:
                return CheckinStatusView(
                  icon: Icons.camera_alt_rounded,
                  title: AppLocalizations.tr('checkin_qr_requesting_camera'),
                  message: AppLocalizations.tr('checkin_qr_camera_needed'),
                  loading: true,
                );
              case QrCheckinStatus.permissionDenied:
                return CheckinStatusView(
                  icon: Icons.no_photography_rounded,
                  title: AppLocalizations.tr('checkin_qr_permission_denied'),
                  message:
                      state.errorMessage ??
                      AppLocalizations.tr('checkin_qr_permission_required'),
                  actionLabel: AppLocalizations.tr('checkin_retry'),
                  onAction: () {
                    context.read<CheckinBloc>().add(
                      const CheckinEvent.qrRetryRequested(),
                    );
                  },
                );
              case QrCheckinStatus.scanning:
                return _ScannerContent(details: details);
              case QrCheckinStatus.success:
                return CheckinStatusView(
                  icon: Icons.verified_rounded,
                  title: AppLocalizations.tr('checkin_qr_detected'),
                  message: AppLocalizations.tr(
                    'checkin_preparing_verification',
                  ),
                  loading: true,
                  success: true,
                );
              case QrCheckinStatus.failure:
                return CheckinStatusView(
                  icon: Icons.error_outline_rounded,
                  title: AppLocalizations.tr('checkin_qr_unable_to_scan'),
                  message:
                      state.errorMessage ??
                      AppLocalizations.tr('checkin_qr_scan_error'),
                  actionLabel: AppLocalizations.tr('checkin_retry'),
                  onAction: () {
                    context.read<CheckinBloc>().add(
                      const CheckinEvent.qrRetryRequested(),
                    );
                  },
                );
            }
          },
        ),
      ),
    );
  }
}

class _ScannerContent extends StatelessWidget {
  const _ScannerContent({required this.details});

  final CheckinEventDetails details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            children: [
              Text(
                AppLocalizations.tr('checkin_qr_scan_heading'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppLocalizations.tr('checkin_qr_scan_desc'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              CheckinEventSummaryCard(details: details),
              const SizedBox(height: AppSpacing.lg),
              CheckinInstructionCard(
                icon: Icons.center_focus_strong_rounded,
                title: AppLocalizations.tr('checkin_camera_ready'),
                message: AppLocalizations.tr('checkin_qr_camera_ready_desc'),
              ),
              const SizedBox(height: AppSpacing.lg),
              QrScannerView(
                onCodeDetected: (value) {
                  context.read<CheckinBloc>().add(
                    CheckinEvent.qrCodeDetected(value),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              const GpsStatusCard(distance: '2m', compact: true),
            ],
          ),
        ),
      ),
    );
  }
}
