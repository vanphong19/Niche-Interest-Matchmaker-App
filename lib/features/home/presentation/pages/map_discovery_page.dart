import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../injection/injection_container.dart';
import '../../../../router/app_router.gr.dart';
import '../../../event/domain/entities/event.dart';
import '../../../event/presentation/bloc/event_bloc.dart';
import '../../../../core/utils/app_localizations.dart';

@RoutePage()
class MapDiscoveryPage extends StatefulWidget {
  const MapDiscoveryPage({super.key});

  @override
  State<MapDiscoveryPage> createState() => _MapDiscoveryPageState();
}

class _MapDiscoveryPageState extends State<MapDiscoveryPage> {
  final MapController _mapController = MapController();
  late final EventBloc _eventBloc;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final PageController _cardPageController = PageController(
    viewportFraction: 0.85,
  );

  String _selectedCategory = 'All';

  final List<Map<String, String>> _categories = [
    {'name': 'All', 'emoji': '🔥'},
    {'name': 'Sports', 'emoji': '🏃'},
    {'name': 'Dining', 'emoji': '🍜'},
    {'name': 'Social', 'emoji': '💬'},
    {'name': 'Arts', 'emoji': '🎨'},
    {'name': 'Outdoors', 'emoji': '⛺'},
    {'name': 'Gaming', 'emoji': '🎮'},
  ];

  @override
  void initState() {
    super.initState();
    _eventBloc = sl<EventBloc>();
    _eventBloc.add(LoadEvents());
    _cardPageController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_cardPageController.page == null) return;
    final maxScroll = _cardPageController.position.maxScrollExtent;
    final currentScroll = _cardPageController.position.pixels;
    if (maxScroll - currentScroll <= 200) {
      if (!_eventBloc.state.isLoading && !_eventBloc.state.hasReachedMax) {
        _eventBloc.add(
          LoadEvents(
            category: _selectedCategory == 'All' ? null : _selectedCategory,
            isRefresh: false,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _cardPageController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {}); // Just trigger rebuild to filter list below
  }

  void _onCategoryTap(String category) {
    HapticFeedback.selectionClick();
    setState(() => _selectedCategory = category);
    _eventBloc.add(LoadEvents(category: category == 'All' ? null : category));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider.value(
      value: _eventBloc,
      child: Scaffold(
        body: Stack(
          children: [
            // Map Layer
            BlocBuilder<EventBloc, EventState>(
              builder: (context, state) {
                final query = _searchCtrl.text.toLowerCase();
                List<Event> events = [];
                if (state.events.isNotEmpty) {
                  events = state.events
                      .where((e) => e.status == EventStatus.active)
                      .where((e) {
                        if (query.isEmpty) return true;
                        return e.title.toLowerCase().contains(query) ||
                            e.categoryName.toLowerCase().contains(query) ||
                            e.location.name.toLowerCase().contains(query) ||
                            (e.vibeTags?.toLowerCase().contains(query) ??
                                false);
                      })
                      .toList();
                }

                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(10.7769, 106.7009),
                    initialZoom: 14.0,
                    onTap: (_, _) {
                      FocusScope.of(context).unfocus();
                    },
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.vibepulse.app',
                      tileBuilder: isDark
                          ? (context, tileWidget, tile) {
                              return ColorFiltered(
                                colorFilter: const ColorFilter.matrix([
                                  -1,
                                  0,
                                  0,
                                  0,
                                  255,
                                  0,
                                  -1,
                                  0,
                                  0,
                                  255,
                                  0,
                                  0,
                                  -1,
                                  0,
                                  255,
                                  0,
                                  0,
                                  0,
                                  1,
                                  0,
                                ]),
                                child: tileWidget,
                              );
                            }
                          : (context, tileWidget, tile) {
                              return ColorFiltered(
                                colorFilter: const ColorFilter.matrix([
                                  0.2126,
                                  0.7152,
                                  0.0722,
                                  0,
                                  0,
                                  0.2126,
                                  0.7152,
                                  0.0722,
                                  0,
                                  0,
                                  0.2126,
                                  0.7152,
                                  0.0722,
                                  0,
                                  0,
                                  0,
                                  0,
                                  0,
                                  1,
                                  0,
                                ]),
                                child: tileWidget,
                              );
                            },
                    ),
                    MarkerLayer(
                      markers: events.map((e) {
                        return Marker(
                          point: LatLng(
                            e.location.latitude,
                            e.location.longitude,
                          ),
                          width: 50,
                          height: 50,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _mapController.move(
                                LatLng(
                                  e.location.latitude,
                                  e.location.longitude,
                                ),
                                15,
                              );
                              context.router.push(
                                EventDetailRoute(eventId: e.id),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  e.categoryEmoji,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),

            // Top Search Bar
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  // Search bar + Back button cùng hàng
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _MapBackButton(isDark: isDark),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          focusNode: _searchFocus,
                          onChanged: _onSearch,
                          textAlignVertical: TextAlignVertical.center,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            constraints: const BoxConstraints(
                              maxHeight:
                                  45, // ← ép đúng height, không để Flutter tự tính
                            ),
                            hintText: AppLocalizations.tr('search_placeholder'),
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
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        _onSearch('');
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
                      ),
                    ],
                  ),
                  // Category filter chips
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat['name'];
                        return Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => _onCategoryTap(cat['name']!),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? Colors.black : Colors.white)
                                          .withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark
                                            ? Colors.white10
                                            : AppColors.borderLight),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    cat['emoji']!,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    cat['name']!,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      fontSize: 13,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                                ? AppColors.darkTextPrimary
                                                : AppColors.secondary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Horizontal Cards - RESTORED SCROLLING
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 165,
                child: BlocBuilder<EventBloc, EventState>(
                  builder: (context, state) {
                    final query = _searchCtrl.text.toLowerCase();
                    final List<Event> filteredEvents = state.events.where((e) {
                      if (query.isEmpty) return true;
                      return e.title.toLowerCase().contains(query) ||
                          e.categoryName.toLowerCase().contains(query) ||
                          e.location.name.toLowerCase().contains(query) ||
                          (e.vibeTags?.toLowerCase().contains(query) ?? false);
                    }).toList();

                    if (filteredEvents.isNotEmpty) {
                      return PageView.builder(
                        controller: _cardPageController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredEvents.length,
                        clipBehavior: Clip.none,
                        onPageChanged: (index) {
                          final event = filteredEvents[index];
                          _mapController.move(
                            LatLng(
                              event.location.latitude,
                              event.location.longitude,
                            ),
                            14.5,
                          );
                        },
                        itemBuilder: (context, index) {
                          final event = filteredEvents[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: _buildGlassCard(event, isDark),
                          );
                        },
                      );
                    }
                    if (filteredEvents.isEmpty && !state.isLoading) {
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCardBackground
                                : Colors.black87,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            AppLocalizations.tr('no_vibes_found'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard(Event event, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _mapController.move(
          LatLng(event.location.latitude, event.location.longitude),
          15,
        );
        context.router.push(EventDetailRoute(eventId: event.id));
      },
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkCardBackground : Colors.white)
                    .withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.white).withValues(
                    alpha: 0.3,
                  ),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 110,
                    height: double.infinity,
                    padding: const EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        event.photoUrls.isNotEmpty
                            ? event.photoUrls.first
                            : 'https://api-prod-minimal-v700.pages.dev/assets/images/cover/cover-${(event.id.hashCode % 20) + 1}.webp',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.bgSecondary,
                          child: const Icon(
                            Icons.image,
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.getCategoryColor(
                                    event.categoryName,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${event.categoryEmoji} ${event.categoryName}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.getCategoryColor(
                                      event.categoryName,
                                    ),
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (event.matchScore > 80)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.bolt_rounded,
                                      size: 14,
                                      color: AppColors.warning,
                                    ),
                                    Text(
                                      '${event.matchScore.toInt()}%',
                                      style: const TextStyle(
                                        color: AppColors.warning,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            event.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.secondary,
                              height: 1.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_filled_rounded,
                                size: 13,
                                color: isDark
                                    ? AppColors.darkTextHint
                                    : AppColors.textHint,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${event.startDateTime.hour}:${event.startDateTime.minute.toString().padLeft(2, '0')} • ${event.startDateTime.day}/${event.startDateTime.month}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 13,
                                color: isDark
                                    ? AppColors.darkTextHint
                                    : AppColors.textHint,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.location.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapBackButton extends StatelessWidget {
  const _MapBackButton({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        context.router.maybePop();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.72)
                  : Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: isDark ? Colors.white : AppColors.secondary,
            ),
          ),
        ),
      ),
    );
  }
}
