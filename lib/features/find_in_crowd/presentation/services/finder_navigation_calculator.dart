import 'package:geolocator/geolocator.dart';

import '../models/finder_location_ui_model.dart';

class FinderNavigationCalculator {
  const FinderNavigationCalculator();

  FinderNavigationUiModel? calculate({
    required FinderLocationUiModel? current,
    required FinderLocationUiModel? target,
    double? lastKnownHeading,
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

    return FinderNavigationUiModel(
      distanceMeters: distance,
      bearingDegrees: normalizedBearing,
      relativeBearingDegrees: relativeBearing,
      directionLabel: _directionLabel(normalizedBearing),
      guidanceLabel: heading == null
          ? 'Head ${_directionLabel(normalizedBearing).toLowerCase()}'
          : _guidanceLabel(relativeBearing),
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
}
