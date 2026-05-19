import 'package:niche_interest_matchmaker_app/features/base/bloc/base_bloc_state.dart';

enum QrCheckinStatus {
  initial,
  requestingPermission,
  permissionDenied,
  scanning,
  success,
  failure,
}

enum NfcCheckinStatus {
  initial,
  checkingAvailability,
  readyToScan,
  scanning,
  success,
  failure,
  unsupported,
  disabled,
}

class CheckinState extends BaseBlocState {
  const CheckinState({
    this.qrStatus = QrCheckinStatus.initial,
    this.nfcStatus = NfcCheckinStatus.initial,
    this.qrPayload,
    this.nfcPayload,
    this.errorMessage,
  });

  final QrCheckinStatus qrStatus;
  final NfcCheckinStatus nfcStatus;
  final String? qrPayload;
  final String? nfcPayload;
  final String? errorMessage;

  bool get isQrLoading => qrStatus == QrCheckinStatus.requestingPermission;

  bool get isNfcLoading =>
      nfcStatus == NfcCheckinStatus.checkingAvailability ||
      nfcStatus == NfcCheckinStatus.readyToScan;

  CheckinState copyWith({
    QrCheckinStatus? qrStatus,
    NfcCheckinStatus? nfcStatus,
    String? qrPayload,
    String? nfcPayload,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return CheckinState(
      qrStatus: qrStatus ?? this.qrStatus,
      nfcStatus: nfcStatus ?? this.nfcStatus,
      qrPayload: qrPayload ?? this.qrPayload,
      nfcPayload: nfcPayload ?? this.nfcPayload,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
