import '../../domain/entities/checkin_request.dart';

class CheckinRequestModel extends CheckinRequest {
  const CheckinRequestModel({
    required super.matchId,
    required super.method,
    required super.payload,
    super.latitude,
    super.longitude,
    super.locationAccuracyMeters,
    super.locationCapturedAtUtc,
    super.deviceId,
    super.clientRequestId,
  });

  factory CheckinRequestModel.fromEntity(CheckinRequest request) {
    return CheckinRequestModel(
      matchId: request.matchId,
      method: request.method,
      payload: request.payload,
      latitude: request.latitude,
      longitude: request.longitude,
      locationAccuracyMeters: request.locationAccuracyMeters,
      locationCapturedAtUtc: request.locationCapturedAtUtc,
      deviceId: request.deviceId,
      clientRequestId: request.clientRequestId,
    );
  }

  Map<String, dynamic> toJson() => {
        'matchId': matchId,
        'method': method,
        'payload': payload,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (locationAccuracyMeters != null)
          'locationAccuracyMeters': locationAccuracyMeters,
        if (locationCapturedAtUtc != null)
          'locationCapturedAtUtc': locationCapturedAtUtc!.toUtc().toIso8601String(),
        if (deviceId != null && deviceId!.isNotEmpty) 'deviceId': deviceId,
        if (clientRequestId != null && clientRequestId!.isNotEmpty)
          'clientRequestId': clientRequestId,
      };
}
