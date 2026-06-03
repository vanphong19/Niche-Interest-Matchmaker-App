import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../../presentation/models/finder_location_ui_model.dart';

class FinderLocationService {
  static const EventChannel _headingChannel = EventChannel(
    'niche_interest_matchmaker/device_heading',
  );
  static StreamController<double>? _headingController;
  static StreamSubscription<dynamic>? _nativeHeadingSubscription;

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
      locationSettings: _currentLocationSettings,
    );
    return FinderLocationUiModel.fromPosition(position);
  }

  Stream<FinderLocationUiModel> watchLocation() async* {
    final permission = await ensurePermission();
    if (permission != FinderLocationPermissionResult.granted) return;
    FinderLocationUiModel? lastRaw;
    FinderLocationUiModel? lastSmoothed;

    yield* Geolocator.getPositionStream(locationSettings: _trackingSettings)
        .map(FinderLocationUiModel.fromPosition)
        .where((location) {
          if (location.accuracyMeters > 80) return false;
          final previous = lastRaw;
          if (previous == null) {
            lastRaw = location;
            return true;
          }

          final elapsedSeconds =
              location.capturedAt
                  .difference(previous.capturedAt)
                  .inMilliseconds /
              1000;
          if (elapsedSeconds <= 0) return true;

          final distance = Geolocator.distanceBetween(
            previous.latitude,
            previous.longitude,
            location.latitude,
            location.longitude,
          );
          final speed = distance / elapsedSeconds;
          final suspiciousJump =
              elapsedSeconds < 4 &&
              distance > location.accuracyMeters.clamp(12, 35) * 2.4;

          final shouldAccept = speed <= 8 || !suspiciousJump;
          if (shouldAccept) lastRaw = location;
          return shouldAccept;
        })
        .map((location) {
          lastSmoothed = _smoothLocation(lastSmoothed, location);
          return lastSmoothed!;
        });
  }

  Stream<double> watchDeviceHeading() {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return const Stream<double>.empty();
    }

    return _sharedDeviceHeadingStream().distinct(_headingsAreClose);
  }

  Future<void> openSettings() => Geolocator.openAppSettings();

  LocationSettings get _currentLocationSettings {
    return const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      timeLimit: Duration(seconds: 10),
    );
  }

  LocationSettings get _trackingSettings {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 1),
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );
  }

  FinderLocationUiModel _smoothLocation(
    FinderLocationUiModel? previous,
    FinderLocationUiModel current,
  ) {
    if (previous == null ||
        current.capturedAt.difference(previous.capturedAt) >
            const Duration(seconds: 8)) {
      return current;
    }

    final distance = Geolocator.distanceBetween(
      previous.latitude,
      previous.longitude,
      current.latitude,
      current.longitude,
    );
    if (distance > 45) return current;

    final alpha = current.accuracyMeters <= 10
        ? 0.68
        : current.accuracyMeters <= 25
        ? 0.50
        : 0.34;

    return FinderLocationUiModel(
      latitude: _lerp(previous.latitude, current.latitude, alpha),
      longitude: _lerp(previous.longitude, current.longitude, alpha),
      accuracyMeters: current.accuracyMeters,
      capturedAt: current.capturedAt,
      headingDegrees: current.headingDegrees ?? previous.headingDegrees,
      speedMetersPerSecond:
          current.speedMetersPerSecond ?? previous.speedMetersPerSecond,
    );
  }

  double _lerp(double from, double to, double alpha) {
    return from + (to - from) * alpha;
  }

  bool _headingsAreClose(double previous, double next) {
    final delta = ((next - previous + 540) % 360) - 180;
    return delta.abs() < 0.8;
  }

  Stream<double> _sharedDeviceHeadingStream() {
    final existingController = _headingController;
    if (existingController != null) return existingController.stream;

    final controller = StreamController<double>.broadcast();
    _headingController = controller;
    _nativeHeadingSubscription ??= _headingChannel
        .receiveBroadcastStream()
        .listen(
          (value) {
            if (value == null || controller.isClosed) return;
            final heading = (value as num).toDouble();
            if (heading >= 0 && heading < 360) controller.add(heading);
          },
          onError: (Object error) {
            if (!controller.isClosed) controller.addError(error);
          },
        );
    return controller.stream;
  }
}

enum FinderLocationPermissionResult {
  granted,
  serviceOff,
  denied,
  deniedForever,
}
