import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/checkin_result.dart';
import '../strategies/check_in_strategy.dart';

class CheckInWithNfcParams {
  const CheckInWithNfcParams({
    required this.matchId,
    required this.rawNfcPayload,
    this.deviceId,
  });

  final String matchId;
  final String rawNfcPayload;
  final String? deviceId;
}

class CheckInWithNfcUseCase {
  const CheckInWithNfcUseCase(this._strategy);

  final NfcCheckInStrategy _strategy;

  Future<Either<Failure, CheckinResult>> call(
    CheckInWithNfcParams params,
  ) {
    return _strategy.checkIn(
      CheckInAttempt(
        matchId: params.matchId,
        payload: params.rawNfcPayload,
        deviceId: params.deviceId,
      ),
    );
  }
}
