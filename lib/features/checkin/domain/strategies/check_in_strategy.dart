import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/checkin_request.dart';
import '../entities/checkin_result.dart';
import '../repositories/checkin_repository.dart';

class CheckInAttempt {
  const CheckInAttempt({
    required this.matchId,
    required this.payload,
    this.latitude,
    this.longitude,
    this.locationAccuracyMeters,
    this.locationCapturedAtUtc,
    this.deviceId,
    this.clientRequestId,
  });

  final String matchId;
  final String payload;
  final double? latitude;
  final double? longitude;
  final double? locationAccuracyMeters;
  final DateTime? locationCapturedAtUtc;
  final String? deviceId;
  final String? clientRequestId;
}

abstract class CheckInStrategy {
  const CheckInStrategy();

  String get method;

  Future<Either<Failure, CheckinResult>> checkIn(CheckInAttempt attempt);
}

class QrCheckInStrategy extends CheckInStrategy {
  const QrCheckInStrategy(this._repository);

  final CheckinRepository _repository;

  @override
  String get method => 'qr';

  @override
  Future<Either<Failure, CheckinResult>> checkIn(CheckInAttempt attempt) {
    return _repository.checkIn(
      CheckinRequest(
        matchId: attempt.matchId,
        method: method,
        payload: attempt.payload,
        latitude: attempt.latitude,
        longitude: attempt.longitude,
        locationAccuracyMeters: attempt.locationAccuracyMeters,
        locationCapturedAtUtc: attempt.locationCapturedAtUtc,
        deviceId: attempt.deviceId,
        clientRequestId: attempt.clientRequestId,
      ),
    );
  }
}

class NfcCheckInStrategy extends CheckInStrategy {
  const NfcCheckInStrategy(this._repository);

  final CheckinRepository _repository;

  @override
  String get method => 'nfc';

  @override
  Future<Either<Failure, CheckinResult>> checkIn(CheckInAttempt attempt) {
    return _repository.checkInWithNfc(
      matchId: attempt.matchId,
      rawNfcPayload: attempt.payload,
      deviceId: attempt.deviceId,
    );
  }
}

class CheckInStrategyRegistry {
  CheckInStrategyRegistry(Iterable<CheckInStrategy> strategies)
      : _strategies = {
          for (final strategy in strategies)
            strategy.method.toLowerCase(): strategy,
        };

  final Map<String, CheckInStrategy> _strategies;

  CheckInStrategy? resolve(String method) {
    return _strategies[method.trim().toLowerCase()];
  }
}
