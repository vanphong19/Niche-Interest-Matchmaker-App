import 'package:niche_interest_matchmaker_app/features/base/bloc/base_bloc_event.dart';

abstract class CheckinEvent extends BaseBlocEvent {
  const CheckinEvent();

  const factory CheckinEvent.started() = CheckinStarted;
  const factory CheckinEvent.qrCheckinRequested({String? matchId}) =
      QrCheckinRequested;
  const factory CheckinEvent.qrRetryRequested() = QrRetryRequested;
  const factory CheckinEvent.qrCodeDetected(String value) = QrCodeDetected;
  const factory CheckinEvent.nfcCheckinRequested({String? matchId}) =
      NfcCheckinRequested;
  const factory CheckinEvent.nfcRetryRequested() = NfcRetryRequested;
  const factory CheckinEvent.nfcTagDetected(String value) = NfcTagDetected;
  const factory CheckinEvent.nfcScanStopped() = NfcScanStopped;
}

class CheckinStarted extends CheckinEvent {
  const CheckinStarted();
}

class QrCheckinRequested extends CheckinEvent {
  const QrCheckinRequested({this.matchId});

  final String? matchId;
}

class QrRetryRequested extends CheckinEvent {
  const QrRetryRequested();
}

class QrCodeDetected extends CheckinEvent {
  const QrCodeDetected(this.value);

  final String value;
}

class NfcCheckinRequested extends CheckinEvent {
  const NfcCheckinRequested({this.matchId});

  final String? matchId;
}

class NfcRetryRequested extends CheckinEvent {
  const NfcRetryRequested();
}

class NfcTagDetected extends CheckinEvent {
  const NfcTagDetected(this.value);

  final String value;
}

class NfcScanStopped extends CheckinEvent {
  const NfcScanStopped();
}
