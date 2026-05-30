import '../../domain/entities/checkin_result.dart';

class CheckinResultModel extends CheckinResult {
  const CheckinResultModel({
    super.checkInId,
    required super.status,
    required super.message,
    required super.matchId,
    super.method,
    super.matchName,
    super.partnerName,
    super.locationName,
    super.checkedInAtUtc,
    super.distanceMeters,
  });

  factory CheckinResultModel.fromJson(Map<String, dynamic> json) {
    return CheckinResultModel(
      checkInId: json['checkInId']?.toString() ?? json['CheckInId']?.toString(),
      status: (json['status'] ?? json['Status'] ?? 'error').toString(),
      message: (json['message'] ?? json['Message'] ?? '').toString(),
      matchId: (json['matchId'] ?? json['MatchId'] ?? '').toString(),
      method: json['method']?.toString() ?? json['Method']?.toString(),
      matchName: json['matchName']?.toString() ?? json['MatchName']?.toString(),
      partnerName:
          json['partnerName']?.toString() ?? json['PartnerName']?.toString(),
      locationName:
          json['locationName']?.toString() ?? json['LocationName']?.toString(),
      checkedInAtUtc: _parseDate(
        json['checkedInAtUtc'] ?? json['CheckedInAtUtc'],
      ),
      distanceMeters: _parseDouble(
        json['distanceMeters'] ?? json['DistanceMeters'],
      ),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
