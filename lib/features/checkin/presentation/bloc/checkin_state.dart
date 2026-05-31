import 'package:niche_interest_matchmaker_app/features/base/bloc/base_bloc_state.dart';
import '../../domain/entities/checkin_eligibility.dart';
import '../../domain/entities/checkin_result.dart';

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
  duplicate,
  rejected,
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
    this.matchId,
    this.startsAt,
    this.endsAt,
    this.eligibility,
    this.result,
    this.errorMessage,
  });

  final QrCheckinStatus qrStatus;
  final NfcCheckinStatus nfcStatus;
  final String? qrPayload;
  final String? nfcPayload;
  final String? matchId;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final CheckinEligibility? eligibility;
  final CheckinResult? result;
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
    String? matchId,
    DateTime? startsAt,
    DateTime? endsAt,
    CheckinEligibility? eligibility,
    CheckinResult? result,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool clearResult = false,
    bool clearEligibility = false,
  }) {
    return CheckinState(
      qrStatus: qrStatus ?? this.qrStatus,
      nfcStatus: nfcStatus ?? this.nfcStatus,
      qrPayload: qrPayload ?? this.qrPayload,
      nfcPayload: nfcPayload ?? this.nfcPayload,
      matchId: matchId ?? this.matchId,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      eligibility: clearEligibility ? null : eligibility ?? this.eligibility,
      result: clearResult ? null : result ?? this.result,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
