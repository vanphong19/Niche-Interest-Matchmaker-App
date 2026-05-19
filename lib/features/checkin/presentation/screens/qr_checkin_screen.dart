import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../bloc/checkin_bloc.dart';
import '../bloc/checkin_event.dart';
import '../bloc/checkin_state.dart';
import '../widgets/checkin_event_summary_card.dart';
import '../widgets/checkin_scaffold.dart';
import '../widgets/checkin_status_view.dart';
import '../widgets/gps_status_card.dart';
import '../widgets/qr_scanner_view.dart';
import '../pages/checkin_verifying_page.dart';

class QrCheckinScreen extends StatelessWidget {
  const QrCheckinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CheckinBloc()..add(const CheckinEvent.qrCheckinRequested()),
      child: const _QrCheckinView(),
    );
  }
}

class _QrCheckinView extends StatelessWidget {
  const _QrCheckinView();

  @override
  Widget build(BuildContext context) {
    return CheckinScaffold(
      title: 'QR Check-in',
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
                  builder: (_) =>
                      const CheckinVerifyingPage(method: 'QR Check-in'),
                ),
              );
            case QrCheckinStatus.permissionDenied:
            case QrCheckinStatus.failure:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.errorMessage ??
                        'QR check-in failed. Please try again.',
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
                return const CheckinStatusView(
                  icon: Icons.camera_alt_rounded,
                  title: 'Requesting camera access',
                  message: 'Camera permission is needed to scan the QR code.',
                  loading: true,
                );
              case QrCheckinStatus.permissionDenied:
                return CheckinStatusView(
                  icon: Icons.no_photography_rounded,
                  title: 'Camera permission denied',
                  message: state.errorMessage ??
                      'Camera permission is required to scan the event QR code.',
                  actionLabel: 'Retry',
                  onAction: () {
                    context
                        .read<CheckinBloc>()
                        .add(const CheckinEvent.qrRetryRequested());
                  },
                );
              case QrCheckinStatus.scanning:
                return const _ScannerContent();
              case QrCheckinStatus.success:
                return const CheckinStatusView(
                  icon: Icons.verified_rounded,
                  title: 'QR code detected',
                  message: 'Preparing secure verification...',
                  loading: true,
                  success: true,
                );
              case QrCheckinStatus.failure:
                return CheckinStatusView(
                  icon: Icons.error_outline_rounded,
                  title: 'Unable to scan QR code',
                  message: state.errorMessage ??
                      'Something went wrong while scanning. Please try again.',
                  actionLabel: 'Retry',
                  onAction: () {
                    context
                        .read<CheckinBloc>()
                        .add(const CheckinEvent.qrRetryRequested());
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
  const _ScannerContent();

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
                'Scan the event QR code',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Allow the camera to focus on the code at the check-in desk.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              const CheckinInstructionCard(
                icon: Icons.center_focus_strong_rounded,
                title: 'Camera ready',
                message:
                    'Keep the QR code flat and inside the frame until verification completes.',
              ),
              const SizedBox(height: AppSpacing.lg),
              QrScannerView(
                onCodeDetected: (value) {
                  context
                      .read<CheckinBloc>()
                      .add(CheckinEvent.qrCodeDetected(value));
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
