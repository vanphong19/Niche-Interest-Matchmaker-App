import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'models/finder_location_ui_model.dart';

class FinderLocationSession {
  FinderLocationSession._();

  static final ValueNotifier<FinderLocationUiModel?> currentLocation =
      ValueNotifier<FinderLocationUiModel?>(null);
  static final ValueNotifier<FinderLocationUiModel?> targetLocation =
      ValueNotifier<FinderLocationUiModel?>(null);

  static void update(FinderLocationUiModel location) {
    currentLocation.value = location;
  }

  static void updateTarget(FinderLocationUiModel location) {
    targetLocation.value = location;
  }

  static void resetTarget() {
    targetLocation.value = null;
  }

  static FinderNavigationUiModel? navigationFrom(
    FinderLocationUiModel? current,
  ) {
    final target = targetLocation.value;
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
    final heading = current.headingDegrees;
    final relativeBearing = heading == null
        ? normalizedBearing
        : (normalizedBearing - heading + 360) % 360;

    return FinderNavigationUiModel(
      distanceMeters: distance,
      bearingDegrees: normalizedBearing,
      relativeBearingDegrees: relativeBearing,
      directionLabel: _directionLabel(normalizedBearing),
      guidanceLabel: _guidanceLabel(relativeBearing),
    );
  }

  static String _directionLabel(double bearing) {
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

  static String _guidanceLabel(double relativeBearing) {
    if (relativeBearing <= 22.5 || relativeBearing >= 337.5) {
      return 'Keep going straight';
    }
    if (relativeBearing < 157.5) return 'Turn right';
    if (relativeBearing <= 202.5) return 'Turn around';
    return 'Turn left';
  }
}
