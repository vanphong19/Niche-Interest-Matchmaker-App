import '../../domain/entities/checkin_eligibility.dart';

class CheckinEligibilityModel extends CheckinEligibility {
  const CheckinEligibilityModel({
    required super.matchId,
    required super.canCheckIn,
    required super.alreadyCheckedIn,
    super.disabledReason,
    required super.windowStartUtc,
    required super.windowEndUtc,
    super.availableMethods,
    super.methods,
    super.location,
    super.existingCheckIn,
  });

  factory CheckinEligibilityModel.fromJson(Map<String, dynamic> json) {
    return CheckinEligibilityModel(
      matchId: (json['matchId'] ?? json['MatchId'] ?? '').toString(),
      canCheckIn: _parseBool(json['canCheckIn'] ?? json['CanCheckIn']),
      alreadyCheckedIn:
          _parseBool(json['alreadyCheckedIn'] ?? json['AlreadyCheckedIn']),
      disabledReason:
          json['disabledReason']?.toString() ??
          json['DisabledReason']?.toString(),
      windowStartUtc:
          _parseDate(json['windowStartUtc'] ?? json['WindowStartUtc']) ??
          DateTime.now().toUtc(),
      windowEndUtc:
          _parseDate(json['windowEndUtc'] ?? json['WindowEndUtc']) ??
          DateTime.now().toUtc(),
      availableMethods:
          ((json['availableMethods'] ?? json['AvailableMethods']) as List?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      methods:
          ((json['methods'] ?? json['Methods']) as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(CheckinMethodAvailabilityModel.fromJson)
              .toList() ??
          const [],
      location: _parseLocation(json['location'] ?? json['Location']),
      existingCheckIn:
          _parseExisting(json['existingCheckIn'] ?? json['ExistingCheckIn']),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toUtc();
  }

  static CheckinLocation? _parseLocation(dynamic value) {
    if (value is Map<String, dynamic>) {
      return CheckinLocationModel.fromJson(value);
    }
    return null;
  }

  static ExistingCheckin? _parseExisting(dynamic value) {
    if (value is Map<String, dynamic>) {
      return ExistingCheckinModel.fromJson(value);
    }
    return null;
  }
}

class CheckinMethodAvailabilityModel extends CheckinMethodAvailability {
  const CheckinMethodAvailabilityModel({
    required super.method,
    required super.enabled,
    super.disabledReason,
    required super.requiresGps,
    required super.requiresCamera,
    required super.requiresNfc,
  });

  factory CheckinMethodAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return CheckinMethodAvailabilityModel(
      method: (json['method'] ?? json['Method'] ?? '').toString(),
      enabled: _parseBool(json['enabled'] ?? json['Enabled']),
      disabledReason:
          json['disabledReason']?.toString() ??
          json['DisabledReason']?.toString(),
      requiresGps: _parseBool(json['requiresGps'] ?? json['RequiresGps']),
      requiresCamera:
          _parseBool(json['requiresCamera'] ?? json['RequiresCamera']),
      requiresNfc: _parseBool(json['requiresNfc'] ?? json['RequiresNfc']),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
  }
}

class CheckinLocationModel extends CheckinLocation {
  const CheckinLocationModel({
    super.partnerLocationId,
    super.partnerName,
    required super.name,
    required super.address,
    super.latitude,
    super.longitude,
    super.checkInRadiusMeters,
  });

  factory CheckinLocationModel.fromJson(Map<String, dynamic> json) {
    return CheckinLocationModel(
      partnerLocationId:
          json['partnerLocationId']?.toString() ??
          json['PartnerLocationId']?.toString(),
      partnerName:
          json['partnerName']?.toString() ?? json['PartnerName']?.toString(),
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      address: (json['address'] ?? json['Address'] ?? '').toString(),
      latitude: _parseDouble(json['latitude'] ?? json['Latitude']),
      longitude: _parseDouble(json['longitude'] ?? json['Longitude']),
      checkInRadiusMeters:
          _parseDouble(json['checkInRadiusMeters'] ?? json['CheckInRadiusMeters']),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class ExistingCheckinModel extends ExistingCheckin {
  const ExistingCheckinModel({
    required super.checkInId,
    required super.method,
    required super.status,
    required super.checkedInAtUtc,
  });

  factory ExistingCheckinModel.fromJson(Map<String, dynamic> json) {
    return ExistingCheckinModel(
      checkInId: (json['checkInId'] ?? json['CheckInId'] ?? '').toString(),
      method: (json['method'] ?? json['Method'] ?? '').toString(),
      status: (json['status'] ?? json['Status'] ?? '').toString(),
      checkedInAtUtc:
          DateTime.tryParse(
            (json['checkedInAtUtc'] ?? json['CheckedInAtUtc'] ?? '')
                .toString(),
          )?.toUtc() ??
          DateTime.now().toUtc(),
    );
  }
}
