import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/checkin_bloc.dart';
import '../bloc/checkin_event.dart';
import '../bloc/checkin_state.dart';
import '../widgets/checkin_scaffold.dart';
import '../widgets/checkin_status_view.dart';
import '../widgets/nfc_scan_view.dart';
import '../pages/checkin_verifying_page.dart';

class NfcCheckinScreen extends StatelessWidget {
  const NfcCheckinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CheckinBloc()..add(const CheckinEvent.nfcCheckinRequested()),
      child: const _NfcCheckinView(),
    );
  }
}

class _NfcCheckinView extends StatelessWidget {
  const _NfcCheckinView();

  @override
  Widget build(BuildContext context) {
    return CheckinScaffold(
      title: 'NFC Check-in',
      leadingIcon: Icons.close_rounded,
      onLeadingPressed: () => Navigator.of(context).maybePop(),
      body: BlocListener<CheckinBloc, CheckinState>(
        listenWhen: (previous, current) =>
            previous.nfcStatus != current.nfcStatus,
        listener: (context, state) {
          switch (state.nfcStatus) {
            case NfcCheckinStatus.success:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      const CheckinVerifyingPage(method: 'NFC Check-in'),
                ),
              );
            case NfcCheckinStatus.failure:
            case NfcCheckinStatus.unsupported:
            case NfcCheckinStatus.disabled:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.errorMessage ??
                        'NFC check-in failed. Please try again.',
                  ),
                ),
              );
            case NfcCheckinStatus.initial:
            case NfcCheckinStatus.checkingAvailability:
            case NfcCheckinStatus.readyToScan:
            case NfcCheckinStatus.scanning:
              break;
          }
        },
        child: BlocBuilder<CheckinBloc, CheckinState>(
          builder: (context, state) {
            switch (state.nfcStatus) {
              case NfcCheckinStatus.initial:
              case NfcCheckinStatus.checkingAvailability:
                return const CheckinStatusView(
                  icon: Icons.contactless_rounded,
                  title: 'Checking NFC',
                  message: 'Checking whether NFC is available on this device.',
                  loading: true,
                );
              case NfcCheckinStatus.readyToScan:
                return const NfcScanView(
                  title: 'Preparing NFC scanner',
                  message: 'Keep your phone near the event NFC tag.',
                  scanning: false,
                );
              case NfcCheckinStatus.scanning:
                return const NfcScanView(
                  title: 'Ready to scan',
                  message: 'Hold your phone near the NFC tag to check in.',
                  scanning: true,
                );
              case NfcCheckinStatus.success:
                return const CheckinStatusView(
                  icon: Icons.verified_rounded,
                  title: 'NFC tag detected',
                  message: 'Preparing secure verification...',
                  loading: true,
                  success: true,
                );
              case NfcCheckinStatus.unsupported:
                return CheckinStatusView(
                  icon: Icons.block_rounded,
                  title: 'NFC is not supported',
                  message: state.errorMessage ??
                      'This device does not support NFC check-in.',
                );
              case NfcCheckinStatus.disabled:
                return CheckinStatusView(
                  icon: Icons.block_rounded,
                  title: 'NFC is turned off',
                  message: state.errorMessage ??
                      'Enable NFC in device settings and try again.',
                  actionLabel: 'Retry',
                  onAction: () {
                    context
                        .read<CheckinBloc>()
                        .add(const CheckinEvent.nfcRetryRequested());
                  },
                );
              case NfcCheckinStatus.failure:
                return CheckinStatusView(
                  icon: Icons.error_outline_rounded,
                  title: 'Unable to start NFC',
                  message: state.errorMessage ??
                      'Something went wrong while starting NFC scanning.',
                  actionLabel: 'Retry',
                  onAction: () {
                    context
                        .read<CheckinBloc>()
                        .add(const CheckinEvent.nfcRetryRequested());
                  },
                );
            }
          },
        ),
      ),
    );
  }
}
