import 'package:geolocator/geolocator.dart';

import '../models/finder_location_ui_model.dart';

class FinderNavigationCalculator {
  const FinderNavigationCalculator();

  FinderNavigationUiModel? calculate({
    required FinderLocationUiModel? current,
    required FinderLocationUiModel? target,
    double? lastKnownHeading,
    bool usesDeviceCompass = false,
  }) {
    if (current == null || target == null) return null;

    final distance = Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      target.latitude,
      target.longitude,
    );
    final bearing = Geolocator.bearingBetween(
      current.latitude,
      current.longitude,
      target.latitude,
      target.longitude,
    );
    final normalizedBearing = (bearing + 360) % 360;
    final heading = current.headingDegrees ?? lastKnownHeading;
    final relativeBearing = heading == null
        ? normalizedBearing
        : (normalizedBearing - heading + 360) % 360;
    final distanceLabel = _distanceLabel(distance);

    return FinderNavigationUiModel(
      distanceMeters: distance,
      bearingDegrees: normalizedBearing,
      relativeBearingDegrees: relativeBearing,
      directionLabel: _directionLabel(normalizedBearing),
      guidanceLabel: heading == null
          ? 'Walk toward ${_directionLabel(normalizedBearing).toLowerCase()}'
          : _guidanceLabel(relativeBearing),
      stepInstructionLabel: heading == null
          ? 'Move $distanceLabel toward ${_directionLabel(normalizedBearing).toLowerCase()}'
          : _stepInstructionLabel(relativeBearing, distanceLabel),
      headingConfidenceLabel: heading == null
          ? 'Approximate compass direction'
          : usesDeviceCompass
          ? 'Direction follows your phone heading'
          : 'Direction follows your movement',
      usesDeviceHeading: heading != null,
    );
  }

  String _directionLabel(double bearing) {
    const labels = [
      'North',
      'North-east',
      'East',
      'South-east',
      'South',
      'South-west',
      'West',
      'North-west',
    ];
    final index = ((bearing + 22.5) / 45).floor() % labels.length;
    return labels[index];
  }

  String _guidanceLabel(double relativeBearing) {
    if (relativeBearing <= 22.5 || relativeBearing >= 337.5) {
      return 'Keep going straight';
    }
    if (relativeBearing < 157.5) return 'Turn right';
    if (relativeBearing <= 202.5) return 'Turn around';
    return 'Turn left';
  }

  String _stepInstructionLabel(double relativeBearing, String distanceLabel) {
    if (relativeBearing <= 22.5 || relativeBearing >= 337.5) {
      return 'Go straight for $distanceLabel';
    }
    if (relativeBearing < 67.5) return 'Slight right, then $distanceLabel';
    if (relativeBearing < 157.5) return 'Turn right, then $distanceLabel';
    if (relativeBearing <= 202.5) return 'Turn around, then $distanceLabel';
    if (relativeBearing <= 292.5) return 'Turn left, then $distanceLabel';
    return 'Slight left, then $distanceLabel';
  }

  String _distanceLabel(double distanceMeters) {
    if (distanceMeters < 10) return '${distanceMeters.toStringAsFixed(1)}m';
    if (distanceMeters < 1000) return '${distanceMeters.round()}m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
  }
}
