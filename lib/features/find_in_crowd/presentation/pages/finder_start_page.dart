import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../router/app_router.gr.dart';
import '../finder_location_session.dart';
import '../mock/finder_mock_data.dart';
import '../models/finder_location_ui_model.dart';
import '../widgets/finder_current_location_card.dart';
import '../widgets/finder_map_background.dart';
import '../widgets/finder_panels.dart';
import '../widgets/finder_scaffold.dart';

@RoutePage()
class FinderStartPage extends StatefulWidget {
  const FinderStartPage({super.key});

  @override
  State<FinderStartPage> createState() => _FinderStartPageState();
}

class _FinderStartPageState extends State<FinderStartPage> {
  FinderLocationUiModel? _location =
      FinderLocationSession.currentLocation.value;
  String? _locationError;
  bool _isLoadingLocation = false;

  Future<bool> _requestCurrentLocation() async {
    if (_isLoadingLocation) return _location != null;
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError =
              'Location services are turned off. Please enable GPS and try again.';
        });
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          _locationError =
              'Location permission was denied. Allow GPS access to use Finder.';
        });
        return false;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError =
              'Location permission is permanently denied. Enable it in app settings.';
        });
        await Geolocator.openAppSettings();
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      final location = FinderLocationUiModel.fromPosition(position);
      FinderLocationSession.resetTarget();
      FinderLocationSession.update(location);
      if (!mounted) return true;
      setState(() => _location = location);
      return true;
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationError =
              'Could not get your current location. Check GPS signal and try again.';
        });
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _startFinder() async {
    final hasLocation = _location != null || await _requestCurrentLocation();
    if (!mounted || !hasLocation) return;
    context.router.replace(const FinderWaitingRoute());
  }

  @override
  Widget build(BuildContext context) {
    return FinderScaffold(
      title: 'Start Finder',
      subtitle: FinderMockData.session.partner.fullName,
      background: const FinderMapBackground(dimmed: true),
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FinderCurrentLocationCard(
                location: _location,
                isLoading: _isLoadingLocation,
                errorMessage: _locationError,
                onRequestLocation: _requestCurrentLocation,
              ),
              const SizedBox(height: AppSpacing.md),
              FinderStartPanel(
                participant: FinderMockData.session.partner,
                onStart: _startFinder,
                onCancel: () => context.router.maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
