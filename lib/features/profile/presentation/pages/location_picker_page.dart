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
  const LocationPickerPage({
    super.key,
    this.initialLocation,
    this.initialPosition,
    this.isReadOnly = false,
  });

  final String? initialLocation;
  final LatLng? initialPosition;
  final bool isReadOnly;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(10.762622, 106.660172); // Default to HCMC
  String _currentName = 'Selected location';
  String _currentAddress = 'Searching...';

  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounce;
  Timer? _reverseDebounce;
  int _reverseSequence = 0;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      if (mounted) setState(() {});
    });
    if (widget.initialPosition != null) {
      _center = widget.initialPosition!;
    }
    if (widget.initialLocation != null) {
      final parts = widget.initialLocation!
          .split('\n')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) _currentName = parts.first;
      if (parts.length > 1) {
        _currentAddress = parts.skip(1).join(', ');
      } else if (parts.isNotEmpty) {
        _currentAddress = parts.first;
      }
    }

    if (widget.initialPosition == null && !widget.isReadOnly) {
      _determinePosition();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _reverseDebounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
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
    final requestId = ++_reverseSequence;
    setState(() {
      _center = point;
      _currentName = 'Finding place...';
      _currentAddress = 'Reading nearby address information';
    });

    _reverseDebounce?.cancel();
    _reverseDebounce = Timer(const Duration(milliseconds: 450), () async {
      final place = await sl<EventApiService>().reverseGeocodePlace(
        lat: point.latitude,
        lng: point.longitude,
      );
      if (!mounted || requestId != _reverseSequence) return;

      setState(() {
        _currentName = place?['name']?.toString().trim().isNotEmpty == true
            ? place!['name'].toString()
            : 'Pinned location';
        _currentAddress =
            place?['address']?.toString().trim().isNotEmpty == true
            ? place!['address'].toString()
            : 'Selected point on the map';
      });
    });
  }

  void _onSearchChanged(String query) {
    setState(() {});
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      await _runSearch(query);
    });
  }

  Future<List<Map<String, dynamic>>> _runSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      if (mounted) {
        setState(() => _suggestions = []);
      }
      return const [];
    }

    final results = await sl<EventApiService>().searchPlaces(trimmed);
    if (mounted) {
      setState(() => _suggestions = results);
    }
    return results;
  }

  Future<void> _submitSearch(String query) async {
    HapticFeedback.selectionClick();
    _debounce?.cancel();
    final candidates = _suggestions.isNotEmpty
        ? _suggestions
        : await _runSearch(query);
    if (candidates.isNotEmpty) {
      _selectSuggestion(candidates.first);
    }
  }

  void _selectSuggestion(Map<String, dynamic> place) {
    final lat = (place['lat'] as num?)?.toDouble();
    final lng = (place['lng'] as num?)?.toDouble();
    final name = place['name'] as String? ?? 'Selected Location';
    final address = place['address'] as String? ?? '';

    if (lat != null && lng != null) {
      final point = LatLng(lat, lng);
      _mapController.move(point, 16);
      _reverseSequence++;
      _reverseDebounce?.cancel();
      setState(() {
        _center = point;
        _currentName = name;
        _currentAddress = address.isNotEmpty ? address : name;
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
                if (hasGesture && !widget.isReadOnly) {
                  _updateAddress(pos.center);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.vibepulse.app',
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Text(
                      'Pin location here',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primary,
                    size: 48,
                  ),
                ],
              ),
            ),
          ),

          // Top Search Bar (Only if not read only)
          if (!widget.isReadOnly)
            Positioned(
              top: MediaQuery.viewPaddingOf(context).top + VibeHeader.headerHeight + 16,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    onChanged: _onSearchChanged,
                    onSubmitted: _submitSearch,
                    textInputAction: TextInputAction.search,
                    textAlignVertical: TextAlignVertical.center,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      constraints: const BoxConstraints(maxHeight: 45),
                      hintText: 'Search for a place...',
                      hintStyle: TextStyle(
                        color: isDark
                            ? AppColors.darkTextHint
                            : AppColors.textHint,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: Container(
                        width: 46,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.search_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 0,
                      ),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? Container(
                              width: 40,
                              alignment: Alignment.center,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.close_rounded, size: 20),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  _runSearch('');
                                  _searchFocus.unfocus();
                                  setState(() {});
                                },
                              ),
                            )
                          : null,
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 0,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.black.withValues(alpha: 0.85)
                          : Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.18)
                              : const Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.2,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.18)
                              : const Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
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
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: isDark ? Colors.white10 : Colors.black12,
                        ),
                        itemBuilder: (context, index) {
                          final s = _suggestions[index];
                          return ListTile(
                            leading: const Icon(Icons.place_rounded, size: 20),
                            title: Text(
                              s['name'] ?? '',
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: Text(
                              s['address'] ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
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
                border: Border.all(
                  color: isDark ? Colors.white10 : AppColors.borderLight,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'LOCATION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textHint,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentName,
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _currentAddress,
                    maxLines: 5,
                    overflow: TextOverflow.visible,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  if (!widget.isReadOnly) ...[
                    const SizedBox(height: 20),
                    VibeButton(
                      label: 'Confirm Selection',
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        final displayName = _currentAddress.isNotEmpty
                            ? _currentAddress
                            : _currentName;
                        context.router.maybePop({
                          'name': _currentName,
                          'address': _currentAddress,
                          'displayName': displayName,
                          'lat': _center.latitude,
                          'lng': _center.longitude,
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          // My Location Button (Only if not read only)
          if (!widget.isReadOnly)
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
                    border: Border.all(
                      color: isDark ? Colors.white10 : AppColors.borderLight,
                    ),
                  ),
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
