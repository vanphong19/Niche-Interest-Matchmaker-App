import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/checkin_eligibility.dart';
import '../../domain/entities/checkin_request.dart';
import '../../domain/entities/checkin_result.dart';
import '../../domain/repositories/checkin_repository.dart';
import '../datasources/checkin_remote_data_source.dart';
import '../models/checkin_request_model.dart';
import '../services/nfc_payload_parser.dart';

class CheckinRepositoryImpl implements CheckinRepository {
  const CheckinRepositoryImpl({
    required CheckinRemoteDataSource remoteDataSource,
    required NfcPayloadParser nfcPayloadParser,
  })  : _remoteDataSource = remoteDataSource,
        _nfcPayloadParser = nfcPayloadParser;

  final CheckinRemoteDataSource _remoteDataSource;
  final NfcPayloadParser _nfcPayloadParser;

  @override
  Future<Either<Failure, CheckinEligibility>> getEligibility(
    String matchId,
  ) async {
    try {
      final result = await _remoteDataSource.getEligibility(matchId);
      return Right(result);
    } catch (e) {
      return Left(DioClient.mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, CheckinResult>> checkIn(CheckinRequest request) async {
    try {
      final result = await _remoteDataSource.checkIn(
        CheckinRequestModel.fromEntity(request),
      );
      return Right(result);
    } catch (e) {
      return Left(DioClient.mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, CheckinResult>> checkInWithNfc({
    required String matchId,
    required String rawNfcPayload,
    String? deviceId,
  }) async {
    try {
      final parsed = _nfcPayloadParser.parse(rawNfcPayload);
      final result = await _remoteDataSource.checkIn(
        CheckinRequestModel(
          matchId: matchId,
          method: 'nfc',
          payload: parsed.code,
          deviceId: deviceId,
        ),
      );
      return Right(result);
    } on FormatException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(DioClient.mapExceptionToFailure(e));
    }
  }
}
