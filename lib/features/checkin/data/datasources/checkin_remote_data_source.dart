import 'package:dio/dio.dart';

import '../models/checkin_eligibility_model.dart';
import '../models/checkin_request_model.dart';
import '../models/checkin_result_model.dart';

class CheckinRemoteDataSource {
  const CheckinRemoteDataSource(this._dio);

  final Dio _dio;

  Future<CheckinEligibilityModel> getEligibility(String matchId) async {
    final response = await _dio.get(
      '/api/app/checkins/eligibility',
      queryParameters: {'matchId': matchId},
    );
    final data = _unwrap(response.data);
    return CheckinEligibilityModel.fromJson(data);
  }

  Future<CheckinResultModel> checkIn(
    CheckinRequestModel request,
  ) async {
    final response = await _dio.post(
      '/api/app/checkins',
      data: request.toJson(),
    );
    final data = _unwrap(response.data);
    return CheckinResultModel.fromJson(data);
  }

  Map<String, dynamic> _unwrap(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'] ?? responseData['Data'];
      if (data is Map<String, dynamic>) return data;
      return responseData;
    }
    return <String, dynamic>{};
  }
}
