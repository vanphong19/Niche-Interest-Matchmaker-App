import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_localizations.dart';
import '../../../../injection/injection_container.dart';
import '../bloc/checkin_bloc.dart';
import '../bloc/checkin_event.dart';
import '../bloc/checkin_state.dart';
import '../models/checkin_event_details.dart';
import '../widgets/checkin_scaffold.dart';
import '../widgets/checkin_status_view.dart';
import '../widgets/nfc_scan_view.dart';
import '../pages/checkin_verifying_page.dart';

class NfcCheckinScreen extends StatelessWidget {
  const NfcCheckinScreen({super.key, this.matchId, this.eventDetails});

  final String? matchId;
  final CheckinEventDetails? eventDetails;

  @override
  Widget build(BuildContext context) {
    final details =
        eventDetails ?? CheckinEventDetails.fallback(matchId: matchId);
    return BlocProvider(
      create: (_) => sl<CheckinBloc>()
        ..add(
          CheckinEvent.nfcCheckinRequested(
            matchId: details.matchId,
            startsAt: details.startsAt,
            endsAt: details.endsAt,
          ),
        ),
      child: _NfcCheckinView(details: details),
    );
  }
}

class _NfcCheckinView extends StatelessWidget {
  const _NfcCheckinView({required this.details});

  final CheckinEventDetails details;

  @override
  Widget build(BuildContext context) {
    return CheckinScaffold(
      title: AppLocalizations.tr('checkin_nfc_method'),
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
                  builder: (_) => CheckinVerifyingPage(
                    method: AppLocalizations.tr('checkin_nfc_method'),
                    result: state.result,
                    eventDetails: details,
                  ),
                ),
              );
            case NfcCheckinStatus.duplicate:
            case NfcCheckinStatus.rejected:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => CheckinVerifyingPage(
                    method: AppLocalizations.tr('checkin_nfc_method'),
                    result: state.result,
                    eventDetails: details,
                  ),
                ),
              );
            case NfcCheckinStatus.failure:
            case NfcCheckinStatus.unsupported:
            case NfcCheckinStatus.disabled:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.errorMessage ??
                        AppLocalizations.tr('checkin_nfc_failed'),
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
                return CheckinStatusView(
                  icon: Icons.contactless_rounded,
                  title: AppLocalizations.tr('checkin_nfc_checking'),
                  message: AppLocalizations.tr('checkin_nfc_checking_desc'),
                  loading: true,
                );
              case NfcCheckinStatus.readyToScan:
                return NfcScanView(
                  title: AppLocalizations.tr('checkin_nfc_preparing'),
                  message: AppLocalizations.tr('checkin_nfc_waiting_title'),
                  scanning: false,
                );
              case NfcCheckinStatus.scanning:
                return NfcScanView(
                  title: AppLocalizations.tr('checkin_nfc_ready'),
                  message: AppLocalizations.tr('checkin_nfc_ready_desc'),
                  scanning: true,
                );
              case NfcCheckinStatus.success:
              case NfcCheckinStatus.duplicate:
              case NfcCheckinStatus.rejected:
                return CheckinStatusView(
                  icon: Icons.verified_rounded,
                  title: AppLocalizations.tr('checkin_nfc_detected'),
                  message: AppLocalizations.tr(
                    'checkin_preparing_verification',
                  ),
                  loading: true,
                  success: true,
                );
              case NfcCheckinStatus.unsupported:
                return CheckinStatusView(
                  icon: Icons.block_rounded,
                  title: AppLocalizations.tr('checkin_nfc_unsupported'),
                  message:
                      state.errorMessage ??
                      AppLocalizations.tr('checkin_nfc_unsupported_desc'),
                );
              case NfcCheckinStatus.disabled:
                return CheckinStatusView(
                  icon: Icons.block_rounded,
                  title: AppLocalizations.tr('checkin_nfc_disabled'),
                  message:
                      state.errorMessage ??
                      AppLocalizations.tr('checkin_nfc_disabled_desc'),
                  actionLabel: AppLocalizations.tr('checkin_retry'),
                  onAction: () {
                    context.read<CheckinBloc>().add(
                      const CheckinEvent.nfcRetryRequested(),
                    );
                  },
                );
              case NfcCheckinStatus.failure:
                return CheckinStatusView(
                  icon: Icons.error_outline_rounded,
                  title: AppLocalizations.tr('checkin_nfc_unable_to_start'),
                  message:
                      state.errorMessage ??
                      AppLocalizations.tr('checkin_nfc_start_error'),
                  actionLabel: AppLocalizations.tr('checkin_retry'),
                  onAction: () {
                    context.read<CheckinBloc>().add(
                      const CheckinEvent.nfcRetryRequested(),
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
