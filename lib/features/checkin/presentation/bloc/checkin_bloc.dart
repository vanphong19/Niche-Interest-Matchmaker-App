import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:niche_interest_matchmaker_app/features/base/bloc/base_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import 'checkin_event.dart';
import 'checkin_state.dart';

@Injectable()
class CheckinBloc extends BaseBloc<CheckinEvent, CheckinState> {
  CheckinBloc() : super(const CheckinState()) {
    on<CheckinEvent>(_onCheckinEvent);
  }

  bool _nfcSessionActive = false;

  Future<void> _onCheckinEvent(
    CheckinEvent event,
    Emitter<CheckinState> emit,
  ) async {
    switch (event) {
      case CheckinStarted():
        await _stopNfcSession();
        emit(const CheckinState());
      case QrCheckinRequested():
      case QrRetryRequested():
        await _requestQrPermission(emit);
      case QrCodeDetected(:final value):
        await _handleQrDetected(value, emit);
      case NfcCheckinRequested():
      case NfcRetryRequested():
        await _startNfcCheckin(emit);
      case NfcTagDetected(:final value):
        await _handleNfcDetected(value, emit);
      case NfcScanStopped():
        await _stopNfcSession();
        emit(state.copyWith(nfcStatus: NfcCheckinStatus.initial));
    }
  }

  Future<void> _requestQrPermission(Emitter<CheckinState> emit) async {
    emit(
      state.copyWith(
        qrStatus: QrCheckinStatus.requestingPermission,
        clearErrorMessage: true,
      ),
    );

    final status = await Permission.camera.request();

    if (status.isGranted) {
      emit(
        state.copyWith(
          qrStatus: QrCheckinStatus.scanning,
          clearErrorMessage: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        qrStatus: QrCheckinStatus.permissionDenied,
        errorMessage:
            'Camera permission is required to scan the event QR code.',
      ),
    );
  }

  Future<void> _handleQrDetected(
    String value,
    Emitter<CheckinState> emit,
  ) async {
    if (state.qrStatus == QrCheckinStatus.success || value.trim().isEmpty) {
      return;
    }

    emit(
      state.copyWith(
        qrStatus: QrCheckinStatus.success,
        qrPayload: value,
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> _startNfcCheckin(Emitter<CheckinState> emit) async {
    emit(
      state.copyWith(
        nfcStatus: NfcCheckinStatus.checkingAvailability,
        clearErrorMessage: true,
      ),
    );

    try {
      final availability = await NfcManager.instance.checkAvailability();

      switch (availability) {
        case NfcAvailability.enabled:
          emit(state.copyWith(nfcStatus: NfcCheckinStatus.readyToScan));
          await _stopNfcSession();
          await NfcManager.instance.startSession(
            pollingOptions: const {NfcPollingOption.iso14443},
            alertMessageIos: 'Hold your device near the event NFC tag.',
            onDiscovered: (tag) {
              add(CheckinEvent.nfcTagDetected(_describeTag(tag)));
            },
          );
          _nfcSessionActive = true;
          emit(state.copyWith(nfcStatus: NfcCheckinStatus.scanning));
        case NfcAvailability.disabled:
          emit(
            state.copyWith(
              nfcStatus: NfcCheckinStatus.disabled,
              errorMessage: 'NFC is turned off. Enable NFC and try again.',
            ),
          );
        case NfcAvailability.unsupported:
          emit(
            state.copyWith(
              nfcStatus: NfcCheckinStatus.unsupported,
              errorMessage: 'This device does not support NFC check-in.',
            ),
          );
      }
    } catch (_) {
      emit(
        state.copyWith(
          nfcStatus: NfcCheckinStatus.failure,
          errorMessage: 'Unable to start NFC scanning. Please try again.',
        ),
      );
    }
  }

  Future<void> _handleNfcDetected(
    String value,
    Emitter<CheckinState> emit,
  ) async {
    await _stopNfcSession();

    emit(
      state.copyWith(
        nfcStatus: NfcCheckinStatus.success,
        nfcPayload: value,
        clearErrorMessage: true,
      ),
    );
  }

  String _describeTag(NfcTag tag) {
    return tag.toString();
  }

  Future<void> _stopNfcSession() async {
    if (!_nfcSessionActive) {
      return;
    }

    try {
      await NfcManager.instance.stopSession(
        alertMessageIos: 'Check-in verified.',
      );
    } finally {
      _nfcSessionActive = false;
    }
  }

  @override
  Future<void> close() async {
    await _stopNfcSession();
    return super.close();
  }
}
