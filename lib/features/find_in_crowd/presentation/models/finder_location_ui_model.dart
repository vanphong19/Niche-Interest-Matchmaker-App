import 'package:geolocator/geolocator.dart';

import '../../../../core/utils/app_localizations.dart';

class FinderLocationUiModel {
  const FinderLocationUiModel({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.capturedAt,
    this.headingDegrees,
    this.speedMetersPerSecond,
  });

  factory FinderLocationUiModel.fromPosition(Position position) {
    final speed = position.speed.isNaN || position.speed < 0
        ? null
        : position.speed;
    final heading = position.heading;
    final reliableHeading =
        heading.isNaN || heading < 0 || (speed != null && speed < 0.7)
        ? null
        : heading;
    return FinderLocationUiModel(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      capturedAt: DateTime.now(),
      headingDegrees: reliableHeading,
      speedMetersPerSecond: speed,
    );
  }

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime capturedAt;
  final double? headingDegrees;
  final double? speedMetersPerSecond;

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
    required this.stepInstructionLabel,
    required this.headingConfidenceLabel,
    required this.usesDeviceHeading,
  });

  final double distanceMeters;
  final double bearingDegrees;
  final double relativeBearingDegrees;
  final String directionLabel;
  final String guidanceLabel;
  final String stepInstructionLabel;
  final String headingConfidenceLabel;
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
    if (!usesDeviceHeading) return AppLocalizations.tr('finder_approx_compass');
    final turnDegrees = relativeBearingDegrees <= 180
        ? relativeBearingDegrees
        : 360 - relativeBearingDegrees;
    if (turnDegrees <= 22.5) {
      return AppLocalizations.tr('finder_straight_ahead');
    }
    final side = relativeBearingDegrees < 180
        ? AppLocalizations.tr('finder_right')
        : AppLocalizations.tr('finder_left');
    return '${AppLocalizations.tr('finder_turn_degrees')} ${turnDegrees.round()} ${AppLocalizations.tr('finder_degrees')} $side';
  }
}
