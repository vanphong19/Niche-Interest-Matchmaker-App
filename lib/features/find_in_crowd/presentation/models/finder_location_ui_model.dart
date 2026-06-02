import 'package:geolocator/geolocator.dart';

class FinderLocationUiModel {
  const FinderLocationUiModel({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.capturedAt,
    this.headingDegrees,
  });

  factory FinderLocationUiModel.fromPosition(Position position) {
    final heading = position.heading;
    return FinderLocationUiModel(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      capturedAt: DateTime.now(),
      headingDegrees: heading.isNaN || heading < 0 ? null : heading,
    );
  }

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime capturedAt;
  final double? headingDegrees;

  String get coordinateLabel {
    return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
  }

  String get accuracyLabel {
    return '+/-${accuracyMeters.toStringAsFixed(0)}m';
  }
}

class FinderNavigationUiModel {
  const FinderNavigationUiModel({
    required this.distanceMeters,
    required this.bearingDegrees,
    required this.relativeBearingDegrees,
    required this.directionLabel,
    required this.guidanceLabel,
    required this.usesDeviceHeading,
  });

  final double distanceMeters;
  final double bearingDegrees;
  final double relativeBearingDegrees;
  final String directionLabel;
  final String guidanceLabel;
  final bool usesDeviceHeading;

  String get distanceLabel {
    if (distanceMeters < 10) return '${distanceMeters.toStringAsFixed(1)}m';
    if (distanceMeters < 1000) return '${distanceMeters.round()}m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
  }

  double get arrowTurns => relativeBearingDegrees / 360;

  bool get isNearby => distanceMeters <= 30;

  bool get isVeryClose => distanceMeters <= 5;

  String get turnDetailLabel {
    if (!usesDeviceHeading) return 'Approximate compass direction';
    final turnDegrees = relativeBearingDegrees <= 180
        ? relativeBearingDegrees
        : 360 - relativeBearingDegrees;
    if (turnDegrees <= 22.5) return 'Straight ahead';
    final side = relativeBearingDegrees < 180 ? 'right' : 'left';
    return 'Turn ${turnDegrees.round()} degrees $side';
  }
}
