class CheckinEligibility {
  const CheckinEligibility({
    required this.matchId,
    required this.canCheckIn,
    required this.alreadyCheckedIn,
    this.disabledReason,
    required this.windowStartUtc,
    required this.windowEndUtc,
    this.availableMethods = const [],
    this.methods = const [],
    this.location,
    this.existingCheckIn,
  });

  final String matchId;
  final bool canCheckIn;
  final bool alreadyCheckedIn;
  final String? disabledReason;
  final DateTime windowStartUtc;
  final DateTime windowEndUtc;
  final List<String> availableMethods;
  final List<CheckinMethodAvailability> methods;
  final CheckinLocation? location;
  final ExistingCheckin? existingCheckIn;

  bool isMethodEnabled(String method) {
    final normalized = method.trim().toLowerCase();
    return methods.any(
      (item) => item.method.toLowerCase() == normalized && item.enabled,
    );
  }

  CheckinMethodAvailability? methodAvailability(String method) {
    final normalized = method.trim().toLowerCase();
    for (final item in methods) {
      if (item.method.toLowerCase() == normalized) return item;
    }
    return null;
  }
}

class CheckinMethodAvailability {
  const CheckinMethodAvailability({
    required this.method,
    required this.enabled,
    this.disabledReason,
    required this.requiresGps,
    required this.requiresCamera,
    required this.requiresNfc,
  });

  final String method;
  final bool enabled;
  final String? disabledReason;
  final bool requiresGps;
  final bool requiresCamera;
  final bool requiresNfc;
}

class CheckinLocation {
  const CheckinLocation({
    this.partnerLocationId,
    this.partnerName,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    this.checkInRadiusMeters,
  });

  final String? partnerLocationId;
  final String? partnerName;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final double? checkInRadiusMeters;
}

class ExistingCheckin {
  const ExistingCheckin({
    required this.checkInId,
    required this.method,
    required this.status,
    required this.checkedInAtUtc,
  });

  final String checkInId;
  final String method;
  final String status;
  final DateTime checkedInAtUtc;
}
