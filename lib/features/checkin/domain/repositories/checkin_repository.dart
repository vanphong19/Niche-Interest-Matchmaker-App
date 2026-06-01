import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/checkin_eligibility.dart';
import '../entities/checkin_request.dart';
import '../entities/checkin_result.dart';

abstract class CheckinRepository {
  Future<Either<Failure, CheckinEligibility>> getEligibility(String matchId);

  Future<Either<Failure, CheckinResult>> checkIn(CheckinRequest request);

  Future<Either<Failure, CheckinResult>> checkInWithNfc({
    required String matchId,
    required String rawNfcPayload,
    String? deviceId,
  });
}
