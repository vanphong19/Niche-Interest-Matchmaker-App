import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

import '../finder_location_session.dart';
import '../models/finder_location_ui_model.dart';

class FinderLocationAutoUpdater extends StatefulWidget {
  const FinderLocationAutoUpdater({super.key, required this.child});

  final Widget child;

  @override
  State<FinderLocationAutoUpdater> createState() =>
      _FinderLocationAutoUpdaterState();
}

class _FinderLocationAutoUpdaterState extends State<FinderLocationAutoUpdater> {
  StreamSubscription<Position>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _startLocationStream();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startLocationStream() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    await _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: _locationSettings,
        ).listen((position) {
          FinderLocationSession.update(
            FinderLocationUiModel.fromPosition(position),
          );
        });
  }

  LocationSettings get _locationSettings {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 1),
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
