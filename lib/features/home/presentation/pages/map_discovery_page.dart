import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../injection/injection_container.dart';
import '../../../../router/app_router.gr.dart';
import '../../../event/domain/entities/event.dart';
import '../../../event/presentation/bloc/event_bloc.dart';

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

  List<Event> _searchResults = [];
  bool _showSuggestions = false;
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
    _searchFocus.addListener(() {
      setState(() {
        if (!_searchFocus.hasFocus) {
          _showSuggestions = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _cardPageController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    if (query.length > 1) {
      // Search across title, category, vibe tags, and location
      final state = _eventBloc.state;
      if (state.events.isNotEmpty) {
        final q = query.toLowerCase();
        final filtered = state.events.where((e) {
          return e.title.toLowerCase().contains(q) ||
              e.categoryName.toLowerCase().contains(q) ||
              (e.vibeTags?.toLowerCase().contains(q) ?? false) ||
              e.location.name.toLowerCase().contains(q) ||
              e.location.address.toLowerCase().contains(q);
        }).toList();
        setState(() {
          _searchResults = filtered;
          _showSuggestions = true;
        });
      } else {
        _eventBloc.add(SearchEvents(query));
      }
    } else if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSuggestions = false;
      });
      _eventBloc.add(
        LoadEvents(
          category: _selectedCategory == 'All' ? null : _selectedCategory,
        ),
      );
    }
  }

  void _onCategoryTap(String category) {
    HapticFeedback.selectionClick();
    setState(() => _selectedCategory = category);
    _eventBloc.add(LoadEvents(category: category == 'All' ? null : category));
    _searchCtrl.clear();
    setState(() => _showSuggestions = false);
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
                List<Event> events = [];
                if (state.events.isNotEmpty) {
                  events = state.events
                      .where((e) => e.status == EventStatus.active)
                      .toList();
                }

                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(10.7769, 106.7009),
                    initialZoom: 14.0,
                    onTap: (_, _) {
                      FocusScope.of(context).unfocus();
                      setState(() => _showSuggestions = false);
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
                  // Search bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 50,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.8)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(23),
                      border: Border.all(
                        color: _searchFocus.hasFocus
                            ? AppColors.primary
                            : (isDark ? Colors.white : Colors.black).withValues(
                                alpha: 0.1,
                              ),
                        width: 1.2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      onChanged: _onSearch,
                      textAlignVertical: TextAlignVertical.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.secondary,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.tr('search_placeholder'),
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppColors.darkTextHint
                              : AppColors.textHint,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        prefixIcon: Center(
                          widthFactor: 1,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16, right: 8),
                            child: const Icon(
                              Icons.search_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 50,
                        ),
                        suffixIcon: Center(
                          widthFactor: 1,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _searchCtrl.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _searchCtrl.clear();
                                      _onSearch('');
                                      _searchFocus.unfocus();
                                    },
                                    behavior: HitTestBehavior.opaque,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withValues(
                                          alpha: 0.2,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: AppColors.textSecondary,
                                        size: 16,
                                      ),
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: () {},
                                    behavior: HitTestBehavior.opaque,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.tune_rounded,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.textSecondary,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 50,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                        filled: false,
                      ),
                    ),
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
                          padding: EdgeInsets.only(
                            right: 8,
                            left: index == 0 ? 0 : 0,
                          ),
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
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.08,
                                          ),
                                          blurRadius: 8,
                                        ),
                                      ],
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
                  // Search Suggestions Dropdown
                  if (_showSuggestions && _searchResults.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.36,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark
                            ? AppColors.darkCardBackground
                            : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            color: isDark
                                ? AppColors.darkBorderLight
                                : AppColors.borderLight,
                            indent: 68,
                          ),
                          itemBuilder: (context, index) {
                            final event = _searchResults[index];
                            return ListTile(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _searchFocus.unfocus();
                                setState(() => _showSuggestions = false);
                                _mapController.move(
                                  LatLng(
                                    event.location.latitude,
                                    event.location.longitude,
                                  ),
                                  15,
                                );
                                context.router.push(
                                  EventDetailRoute(eventId: event.id),
                                );
                              },
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.getCategoryColor(
                                    event.categoryName,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    event.categoryEmoji,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ),
                              ),
                              title: Text(
                                event.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.secondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${event.categoryName} • ${event.location.name}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${event.matchScore.toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
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
                    if (state.events.isNotEmpty) {
                      return PageView.builder(
                        controller: _cardPageController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: state.events.length,
                        clipBehavior: Clip.none,
                        onPageChanged: (index) {
                          final event = state.events[index];
                          _mapController.move(
                            LatLng(
                              event.location.latitude,
                              event.location.longitude,
                            ),
                            14.5,
                          );
                        },
                        itemBuilder: (context, index) {
                          final event = state.events[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: _buildGlassCard(event, isDark),
                          );
                        },
                      );
                    }
                    if (state.events.isEmpty && !state.isLoading) {
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
                            : 'https://picsum.photos/200',
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
