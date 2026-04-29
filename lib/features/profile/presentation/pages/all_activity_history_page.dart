// lib/features/profile/presentation/pages/all_activity_history_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:auto_route/auto_route.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/profile_state.dart';
import '../../../event/data/services/event_api_service.dart';
import '../../../event/domain/entities/event.dart';
import '../../../../injection/injection_container.dart';
import '../../../../router/app_router.gr.dart';

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
  late Future<Map<String, List<Event>>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.index = widget.initialTab.clamp(0, 2);
    _eventsFuture = sl<EventApiService>().getMyEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _eventsFuture = sl<EventApiService>().getMyEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF0E121A) : const Color(0xFFF5F7FF);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          _buildPremiumHeader(isDark),
          Expanded(
            child: FutureBuilder<Map<String, List<Event>>>(
              future: _eventsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return _buildLoadingState();
                }
                final data = snapshot.data!;
                return RefreshIndicator(
                  onRefresh: _refresh,
                  color: AppColors.primary,
                  backgroundColor: Colors.white,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(data['hosting'] ?? const [], isDark: isDark),
                      _buildList(data['joined'] ?? const [], isDark: isDark),
                      _buildList(data['past'] ?? const [],
                          isDark: isDark, isPast: true),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(bool isDark) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: isDark
              ? const Color(0xFF0E121A).withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.9),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Nav bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : AppColors.bgSecondary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Activity History',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.secondary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'Tap 📌 to pin events to profile',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Custom pill tab bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : AppColors.bgSecondary,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : AppColors.borderLight,
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      padding: const EdgeInsets.all(4),
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textHint,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      tabs: const [
                        Tab(text: 'Hosting'),
                        Tab(text: 'Joined'),
                        Tab(text: 'Past'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: List.generate(
        5,
        (i) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 130,
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildList(
    List<Event> events, {
    bool isDark = false,
    bool isPast = false,
  }) {
    if (events.isEmpty) {
      return _buildEmptyState(isDark, isPast);
    }

    return ValueListenableBuilder<Set<String>>(
      valueListenable: ProfileState.pinnedEventIdsNotifier,
      builder: (context, pinnedIds, _) {
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            final isPinned = pinnedIds.contains(event.id);
            return _ActivityCard(
              event: event,
              isPinned: isPinned,
              isPast: isPast,
              isDark: isDark,
              showPinAction: widget.showPinActions,
              onTap: () {
                HapticFeedback.selectionClick();
                context.router.push(EventDetailRoute(eventId: event.id));
              },
              onPin: () {
                HapticFeedback.mediumImpact();
                ProfileState.togglePinnedEvent(event.id);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark, bool isPast) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : AppColors.bgSecondary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPast
                      ? Icons.history_rounded
                      : Icons.event_busy_rounded,
                  size: 44,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textHint,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isPast ? 'No past events yet' : 'Nothing here yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  isPast
                      ? 'Events you attended will appear here'
                      : 'Join or host events to see them here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textHint,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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

  Color get _categoryColor => AppColors.getCategoryColor(event.categoryName);

  @override
  Widget build(BuildContext context) {
    final date =
        '${event.startDateTime.day}/${event.startDateTime.month}/${event.startDateTime.year}';
    final time =
        '${event.startDateTime.hour.toString().padLeft(2, '0')}:${event.startDateTime.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF171D2A) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isPinned
                ? AppColors.primary.withValues(alpha: 0.4)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.borderLight),
            width: isPinned ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isPinned
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(22)),
              child: Stack(
                children: [
                  Image.network(
                    event.photoUrls.isNotEmpty
                        ? event.photoUrls.first
                        : 'https://picsum.photos/seed/${event.id}/200/200',
                    width: 110,
                    height: 130,
                    fit: BoxFit.cover,
                    errorBuilder: (e, s, t) => Container(
                      width: 110,
                      height: 130,
                      color: AppColors.bgSecondary,
                      child: const Icon(Icons.image_not_supported,
                          color: AppColors.textHint),
                    ),
                  ),
                  // Status overlay
                  if (isPast)
                    Container(
                      width: 110,
                      height: 130,
                      color: Colors.black.withValues(alpha: 0.35),
                      child: const Center(
                        child: Text(
                          'DONE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  // Category chip
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _categoryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event.categoryEmoji,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.secondary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Location
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textHint),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location.name.isNotEmpty
                                ? event.location.name
                                : 'TBD',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textHint,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Date & time
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          '$date · $time',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Bottom row: participants + pin
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _categoryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '👥 ${event.currentParticipants}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _categoryColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (showPinAction)
                          GestureDetector(
                            onTap: onPin,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isPinned
                                    ? AppColors.primary
                                        .withValues(alpha: 0.15)
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.07)
                                        : AppColors.bgSecondary),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPinned
                                    ? Icons.push_pin_rounded
                                    : Icons.push_pin_outlined,
                                size: 16,
                                color: isPinned
                                    ? AppColors.primary
                                    : AppColors.textHint,
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
    );
  }
}
