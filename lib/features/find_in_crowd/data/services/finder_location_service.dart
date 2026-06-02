import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../presentation/models/finder_location_ui_model.dart';

class FinderLocationService {
  Future<FinderLocationPermissionResult> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return FinderLocationPermissionResult.serviceOff;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return FinderLocationPermissionResult.denied;
    }
    if (permission == LocationPermission.deniedForever) {
      return FinderLocationPermissionResult.deniedForever;
    }
    return FinderLocationPermissionResult.granted;
  }

  Future<FinderLocationUiModel?> currentLocation() async {
    final permission = await ensurePermission();
    if (permission != FinderLocationPermissionResult.granted) return null;
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );
    return FinderLocationUiModel.fromPosition(position);
  }

  Stream<FinderLocationUiModel> watchLocation() async* {
    final permission = await ensurePermission();
    if (permission != FinderLocationPermissionResult.granted) return;
    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      ),
    )
        .map(FinderLocationUiModel.fromPosition)
        .where((location) => location.accuracyMeters <= 100);
  }

  Future<void> openSettings() => Geolocator.openAppSettings();
}

enum FinderLocationPermissionResult {
  granted,
  serviceOff,
  denied,
  deniedForever,
}
