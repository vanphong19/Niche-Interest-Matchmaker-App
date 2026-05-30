import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/checkin_request.dart';
import '../entities/checkin_result.dart';
import '../repositories/checkin_repository.dart';

class CheckInUseCase {
  const CheckInUseCase(this._repository);

  final CheckinRepository _repository;

  Future<Either<Failure, CheckinResult>> call(CheckinRequest request) {
    return _repository.checkIn(request);
  }
}
