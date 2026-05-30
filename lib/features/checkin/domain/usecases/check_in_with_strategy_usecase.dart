import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/checkin_result.dart';
import '../strategies/check_in_strategy.dart';

class CheckInWithStrategyParams extends CheckInAttempt {
  const CheckInWithStrategyParams({
    required this.method,
    required super.matchId,
    required super.payload,
    super.latitude,
    super.longitude,
    super.locationAccuracyMeters,
    super.locationCapturedAtUtc,
    super.deviceId,
    super.clientRequestId,
  });

  final String method;
}

class CheckInWithStrategyUseCase {
  const CheckInWithStrategyUseCase(this._registry);

  final CheckInStrategyRegistry _registry;

  Future<Either<Failure, CheckinResult>> call(
    CheckInWithStrategyParams params,
  ) {
    final strategy = _registry.resolve(params.method);
    if (strategy == null) {
      return Future.value(
        Left(ValidationFailure('Unsupported check-in method: ${params.method}')),
      );
    }
    return strategy.checkIn(params);
  }
}
