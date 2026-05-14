// lib/features/profile/presentation/pages/all_activity_history_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:auto_route/auto_route.dart';
import '../../../../core/utils/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/profile_state.dart';
import '../../../event/data/services/event_api_service.dart';
import '../../../event/domain/entities/event.dart';
import '../../../../injection/injection_container.dart';
import '../../../../router/app_router.gr.dart';
import '../../../../core/widgets/vibe_header.dart';

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
    final bgColor = isDark ? const Color(0xFF0E121A) : const Color(0xFFF5F7FF);

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: VibeHeader(
        title: AppLocalizations.tr('activity_history'),
        subtitle: AppLocalizations.tr('manage_earnings'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
              child: TabBar(
                controller: _tabController,
                padding: const EdgeInsets.all(4),
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                splashFactory: NoSplash.splashFactory,
                labelColor: Colors.white,
                unselectedLabelColor: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textHint,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(text: AppLocalizations.tr('hosting')),
                  Tab(text: AppLocalizations.tr('joined')),
                  Tab(text: AppLocalizations.tr('past')),
                ],
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<Map<String, List<Event>>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final hosting = data['hosting'] ?? [];
          final joined = data['joined'] ?? [];
          final past = data['past'] ?? [];

          return TabBarView(
            controller: _tabController,
            children: [
              _buildActivityList(hosting, false),
              _buildActivityList(joined, false),
              _buildActivityList(past, true),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActivityList(List<Event> events, bool isPast) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note_rounded,
              size: 64,
              color: AppColors.textHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No events found',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ValueListenableBuilder<Set<String>>(
        valueListenable: ProfileState.pinnedEventIdsNotifier,
        builder: (context, pinnedIds, _) {
          final sortedEvents = List<Event>.from(events);
          sortedEvents.sort((a, b) {
            final aPinned = pinnedIds.contains(a.id);
            final bPinned = pinnedIds.contains(b.id);
            if (aPinned && !bPinned) return -1;
            if (!aPinned && bPinned) return 1;
            return 0;
          });

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(20, 148, 20, 10),
            itemCount: sortedEvents.length,
            itemBuilder: (context, index) {
              final event = sortedEvents[index];
              final isPinned = pinnedIds.contains(event.id);

              return _ActivityCard(
                event: event,
                isPinned: isPinned,
                isPast: isPast,
                isDark: Theme.of(context).brightness == Brightness.dark,
                showPinAction: widget.showPinActions,
                onTap: () =>
                    context.router.push(EventDetailRoute(eventId: event.id)),
                onPin: () {
                  HapticFeedback.lightImpact();
                  ProfileState.togglePinnedEvent(event.id);
                },
              );
            },
          );
        },
      ),
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
                    Image.network(
                      event.photoUrls.isNotEmpty
                          ? event.photoUrls.first
                          : 'https://picsum.photos/seed/${event.id}/200/200',
                      fit: BoxFit.cover,
                      errorBuilder: (e, s, t) => Container(
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
