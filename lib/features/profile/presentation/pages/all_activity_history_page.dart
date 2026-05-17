// lib/features/profile/presentation/pages/all_activity_history_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/utils/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/profile_state.dart';
import '../../../event/data/services/event_api_service.dart';
import '../../../event/domain/entities/event.dart';
import '../../../../injection/injection_container.dart';
import '../../../../router/app_router.gr.dart';
import '../../../../core/widgets/vibe_empty_state.dart';
import '../../../../core/widgets/vibe_header.dart';
import '../../data/services/user_api_service.dart';

@RoutePage()
class AllActivityHistoryPage extends StatefulWidget {
  const AllActivityHistoryPage({
    super.key,
    this.initialTab = 1,
    this.showPinActions = true,
  });

  final int initialTab;
  final bool showPinActions;

  @override
  State<AllActivityHistoryPage> createState() => _AllActivityHistoryPageState();
}

class _AllActivityHistoryPageState extends State<AllActivityHistoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<List<Event>> _events = [[], [], []];
  final List<bool> _isLoading = [false, false, false];
  final List<bool> _hasMore = [true, true, true];
  final List<int> _totalCounts = [0, 0, 0];

  final List<ScrollController> _scrollControllers = [
    ScrollController(),
    ScrollController(),
    ScrollController(),
  ];

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.index = widget.initialTab.clamp(0, 2);

    // Initial page load
    _loadPage(0, isRefresh: true);
    _loadPage(1, isRefresh: true);
    _loadPage(2, isRefresh: true);

    // Scroll listeners for lazy loading / pagination
    for (int i = 0; i < 3; i++) {
      _scrollControllers[i].addListener(() {
        if (!_scrollControllers[i].hasClients) return;
        final threshold = _scrollControllers[i].position.maxScrollExtent - 200;
        if (_scrollControllers[i].position.pixels >= threshold) {
          _loadPage(i);
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    for (var controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPage(int tabIndex, {bool isRefresh = false}) async {
    if (_isLoading[tabIndex]) return;
    if (!isRefresh && !_hasMore[tabIndex]) return;

    if (mounted) {
      setState(() {
        _isLoading[tabIndex] = true;
      });
    }

    try {
      final tabNames = ['hosted', 'joining', 'past'];
      final String tabName = tabNames[tabIndex];
      const int limit = 10;
      final int offset = isRefresh ? 0 : _events[tabIndex].length;

      final result = await sl<EventApiService>().getMyEventsPaginated(
        tab: tabName,
        search: _searchController.text,
        limit: limit,
        offset: offset,
      );

      final List<Event> newItems = result['items'] as List<Event>;
      final int total = result['totalCount'] as int;

      if (!mounted) return;

      setState(() {
        if (isRefresh) {
          _events[tabIndex] = newItems;
        } else {
          _events[tabIndex].addAll(newItems);
        }

        _isLoading[tabIndex] = false;
        _hasMore[tabIndex] = _events[tabIndex].length < total;
        _totalCounts[tabIndex] = total;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading[tabIndex] = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadPage(0, isRefresh: true);
      _loadPage(1, isRefresh: true);
      _loadPage(2, isRefresh: true);
    });
  }

  Future<void> _refresh() async {
    final currentTab = _tabController.index;
    await _loadPage(currentTab, isRefresh: true);
    try {
      final profile = await sl<UserApiService>().getProfile();
      ProfileState.updateProfile(profile);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0E121A) : const Color(0xFFF5F7FF);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // 1. Full-screen TabBarView at the bottom of the stack
          TabBarView(
            controller: _tabController,
            children: [
              _buildActivityList(0, false),
              _buildActivityList(1, false),
              _buildActivityList(2, true),
            ],
          ),
          // 2. Positioned Floating Glassmorphic VibeHeader at the top of the stack
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: VibeHeader(
              title: AppLocalizations.tr('activity_history'),
              subtitle: AppLocalizations.tr('manage_earnings'),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(122),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // TabBar Container
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFF1F4F9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: ValueListenableBuilder<ProfileData>(
                          valueListenable: ProfileState.notifier,
                          builder: (context, profileData, _) {
                            return TabBar(
                              controller: _tabController,
                              padding: const EdgeInsets.all(4),
                              indicator: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.transparent,
                              overlayColor: WidgetStateProperty.all(
                                Colors.transparent,
                              ),
                              splashFactory: NoSplash.splashFactory,
                              labelColor: Colors.white,
                              unselectedLabelColor: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textHint,
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                              tabs: [
                                Tab(
                                  text:
                                      '${AppLocalizations.tr('hosted')} (${profileData.hostedCount})',
                                ),
                                Tab(
                                  text:
                                      '${AppLocalizations.tr('attending')} (${profileData.attendingCount})',
                                ),
                                Tab(
                                  text:
                                      '${AppLocalizations.tr('past')} (${profileData.pastCount})',
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    // Search Input Container
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
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
                            maxHeight: 45,
                          ),
                          hintText:
                              '${AppLocalizations.tr('search_placeholder')}...',
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
                          suffixIcon: _searchController.text.isNotEmpty
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
                                      _searchController.clear();
                                      _onSearchChanged('');
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
                              ? Colors.white.withValues(alpha: 0.06)
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
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFFE2E8F0),
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
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList(int tabIndex, bool isPast) {
    final rawEvents = _events[tabIndex];
    final isLoading = _isLoading[tabIndex];
    final hasMore = _hasMore[tabIndex];

    return ValueListenableBuilder<Set<String>>(
      valueListenable: ProfileState.pinnedEventIdsNotifier,
      builder: (context, pinnedIds, _) {
        final double topPadding = MediaQuery.paddingOf(context).top + 198.0;
        final sortedEvents = List<Event>.from(rawEvents);
        sortedEvents.sort((a, b) {
          final aPinned = pinnedIds.contains(a.id);
          final bPinned = pinnedIds.contains(b.id);
          if (aPinned && !bPinned) return -1;
          if (!aPinned && bPinned) return 1;
          return 0;
        });

        if (sortedEvents.isEmpty && !isLoading) {
          return RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20, topPadding, 20, 100),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  VibeEmptyState(
                    title: AppLocalizations.tr('no_events_yet'),
                    message:
                        'Your activity will show up here when you host or join events.',
                    icon: isPast
                        ? Icons.history_rounded
                        : Icons.event_available_rounded,
                  ),
                ],
              ),
            ),
          );
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          child: ListView.builder(
            controller: _scrollControllers[tabIndex],
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, topPadding, 20, 80),
            itemCount: sortedEvents.length + 1,
            itemBuilder: (context, index) {
              if (index == sortedEvents.length) {
                if (isLoading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  );
                } else if (!hasMore && sortedEvents.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'All events loaded',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSecondary.withValues(
                                  alpha: 0.5,
                                )
                              : AppColors.textHint,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox(height: 20);
              }

              final event = sortedEvents[index];
              final isPinned = pinnedIds.contains(event.id);

              return _ActivityCard(
                event: event,
                isPinned: isPinned,
                isPast: isPast,
                isDark: isDark,
                showPinAction: widget.showPinActions,
                onTap: () =>
                    context.router.push(EventDetailRoute(eventId: event.id)),
                onPin: () {
                  HapticFeedback.lightImpact();
                  ProfileState.togglePinnedEvent(event.id);
                },
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Activity Card ─────────────────────────────────────────────────────────────
class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.event,
    required this.isPinned,
    required this.isPast,
    required this.isDark,
    required this.showPinAction,
    required this.onTap,
    required this.onPin,
  });

  final Event event;
  final bool isPinned;
  final bool isPast;
  final bool isDark;
  final bool showPinAction;
  final VoidCallback onTap;
  final VoidCallback onPin;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 140,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF171D2A) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isPinned
                ? const Color(0xFF2563EB)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05)),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.5),
          child: Row(
            children: [
              // Image
              SizedBox(
                width: 110,
                height: 140,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: event.photoUrls.isNotEmpty
                          ? event.photoUrls.first
                          : 'https://api-prod-minimal-v700.pages.dev/assets/images/cover/cover-${(event.id.hashCode % 20) + 1}.webp',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFE2E8F0),
                        highlightColor: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFF1F5F9),
                        child: Container(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.bgSecondary,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: AppColors.textHint,
                          size: 20,
                        ),
                      ),
                    ),
                    if (isPast)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.4),
                          child: const Center(
                            child: Text(
                              'DONE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1C2C58),
                              ),
                            ),
                          ),
                          if (isPinned)
                            const Icon(
                              Icons.push_pin_rounded,
                              size: 14,
                              color: Color(0xFF2563EB),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              event.categoryName.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              event.location.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : AppColors.bgSecondary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${event.currentParticipants}/${event.maxParticipants}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                          if (showPinAction)
                            GestureDetector(
                              onTap: onPin,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isPinned
                                      ? const Color(0xFF2563EB)
                                      : (isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.1,
                                              )
                                            : const Color(0xFFF1F5F9)),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isPinned
                                      ? Icons.push_pin_rounded
                                      : Icons.push_pin_outlined,
                                  size: 18,
                                  color: isPinned
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                ),
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
    );
  }
}
