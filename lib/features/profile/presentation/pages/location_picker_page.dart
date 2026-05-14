// lib/features/profile/presentation/pages/location_picker_page.dart
import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/vibe_button.dart';
import '../../../../core/widgets/vibe_header.dart';
import '../../../../injection/injection_container.dart';
import '../../../event/data/services/event_api_service.dart';

@RoutePage()
class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key, this.initialLocation});

  final String? initialLocation;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(10.762622, 106.660172); // Default to HCMC
  String _currentAddress = 'Searching...';
  
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      final newCenter = LatLng(position.latitude, position.longitude);
      
      setState(() => _center = newCenter);
      _mapController.move(newCenter, 15);
      _updateAddress(newCenter);
    } catch (_) {}
  }

  Future<void> _updateAddress(LatLng point) async {
    // In a real app, you'd use reverse geocoding here.
    // For this demo, we'll simulate it or use the BE if available.
    setState(() {
      _center = point;
      _currentAddress = 'Lat: ${point.latitude.toStringAsFixed(4)}, Lng: ${point.longitude.toStringAsFixed(4)}';
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() => _suggestions = []);
        return;
      }
      final results = await sl<EventApiService>().searchPlaces(query);
      setState(() => _suggestions = results);
    });
  }

  void _selectSuggestion(Map<String, dynamic> place) {
    final lat = place['lat'] as double?;
    final lng = place['lng'] as double?;
    final name = place['name'] as String? ?? 'Selected Location';

    if (lat != null && lng != null) {
      final point = LatLng(lat, lng);
      _mapController.move(point, 16);
      setState(() {
        _center = point;
        _currentAddress = name;
        _suggestions = [];
        _searchCtrl.clear();
      });
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: VibeHeader(
        title: 'Select Location',
        onBackTap: () => context.router.maybePop(),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture) {
                  _updateAddress(pos.center);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: isDark
                    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                    : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
            ],
          ),
          
          // Fixed Center Marker
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: const Text(
                      'Pin location here',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 48),
                ],
              ),
            ),
          ),

          // Top Search Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search for a place...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),
                ),
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _suggestions.length,
                      separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                      itemBuilder: (context, index) {
                        final s = _suggestions[index];
                        return ListTile(
                          leading: const Icon(Icons.place_rounded, size: 20),
                          title: Text(s['name'] ?? '', style: const TextStyle(fontSize: 14)),
                          subtitle: Text(s['address'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          onTap: () => _selectSuggestion(s),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Selection Card
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0E121A) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'SELECTED LOCATION',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textHint, letterSpacing: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  VibeButton(
                    label: 'Confirm Selection',
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      context.router.maybePop(_currentAddress);
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // My Location Button
          Positioned(
            bottom: 240,
            right: 20,
            child: GestureDetector(
              onTap: _determinePosition,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: const Icon(Icons.my_location_rounded, color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
