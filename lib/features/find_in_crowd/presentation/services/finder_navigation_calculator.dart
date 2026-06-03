import 'package:geolocator/geolocator.dart';

import '../../../../core/utils/app_localizations.dart';
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
          ? '${AppLocalizations.tr('finder_walk_toward')} ${_directionLabel(normalizedBearing).toLowerCase()}'
          : _guidanceLabel(relativeBearing),
      stepInstructionLabel: heading == null
          ? '${AppLocalizations.tr('finder_move')} $distanceLabel ${AppLocalizations.tr('finder_toward')} ${_directionLabel(normalizedBearing).toLowerCase()}'
          : _stepInstructionLabel(relativeBearing, distanceLabel),
      headingConfidenceLabel: heading == null
          ? AppLocalizations.tr('finder_approx_compass')
          : usesDeviceCompass
          ? AppLocalizations.tr('finder_phone_heading')
          : AppLocalizations.tr('finder_movement_heading'),
      usesDeviceHeading: heading != null,
    );
  }

  String _directionLabel(double bearing) {
    const labels = [
      'finder_north',
      'finder_north_east',
      'finder_east',
      'finder_south_east',
      'finder_south',
      'finder_south_west',
      'finder_west',
      'finder_north_west',
    ];
    final index = ((bearing + 22.5) / 45).floor() % labels.length;
    return AppLocalizations.tr(labels[index]);
  }

  String _guidanceLabel(double relativeBearing) {
    if (relativeBearing <= 22.5 || relativeBearing >= 337.5) {
      return AppLocalizations.tr('finder_keep_straight');
    }
    if (relativeBearing < 157.5) {
      return AppLocalizations.tr('finder_turn_right');
    }
    if (relativeBearing <= 202.5) {
      return AppLocalizations.tr('finder_turn_around');
    }
    return AppLocalizations.tr('finder_turn_left');
  }

  String _stepInstructionLabel(double relativeBearing, String distanceLabel) {
    if (relativeBearing <= 22.5 || relativeBearing >= 337.5) {
      return '${AppLocalizations.tr('finder_go_straight_for')} $distanceLabel';
    }
    if (relativeBearing < 67.5) {
      return '${AppLocalizations.tr('finder_slight_right_then')} $distanceLabel';
    }
    if (relativeBearing < 157.5) {
      return '${AppLocalizations.tr('finder_turn_right_then')} $distanceLabel';
    }
    if (relativeBearing <= 202.5) {
      return '${AppLocalizations.tr('finder_turn_around_then')} $distanceLabel';
    }
    if (relativeBearing <= 292.5) {
      return '${AppLocalizations.tr('finder_turn_left_then')} $distanceLabel';
    }
    return '${AppLocalizations.tr('finder_slight_left_then')} $distanceLabel';
  }

  String _distanceLabel(double distanceMeters) {
    if (distanceMeters < 10) return '${distanceMeters.toStringAsFixed(1)}m';
    if (distanceMeters < 1000) return '${distanceMeters.round()}m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
  }
}
