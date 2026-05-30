class CheckinRequest {
  const CheckinRequest({
    required this.matchId,
    required this.method,
    required this.payload,
    this.latitude,
    this.longitude,
    this.locationAccuracyMeters,
    this.locationCapturedAtUtc,
    this.deviceId,
    this.clientRequestId,
  });

  final String matchId;
  final String method;
  final String payload;
  final double? latitude;
  final double? longitude;
  final double? locationAccuracyMeters;
  final DateTime? locationCapturedAtUtc;
  final String? deviceId;
  final String? clientRequestId;
}
