import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/checkin_eligibility.dart';
import '../repositories/checkin_repository.dart';

class GetCheckinEligibilityUseCase {
  const GetCheckinEligibilityUseCase(this._repository);

  final CheckinRepository _repository;

  Future<Either<Failure, CheckinEligibility>> call(String matchId) {
    return _repository.getEligibility(matchId);
  }
}
