class CheckinResult {
  const CheckinResult({
    this.checkInId,
    required this.status,
    required this.message,
    required this.matchId,
    this.method,
    this.matchName,
    this.partnerName,
    this.locationName,
    this.checkedInAtUtc,
    this.distanceMeters,
  });

  final String? checkInId;
  final String status;
  final String message;
  final String matchId;
  final String? method;
  final String? matchName;
  final String? partnerName;
  final String? locationName;
  final DateTime? checkedInAtUtc;
  final double? distanceMeters;

  bool get isValid => status == 'valid';
  bool get isDuplicate => status == 'duplicate';
}
