import 'dart:ui';
import 'package:auto_route/auto_route.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../injection/injection_container.dart';
import '../../../../router/app_router.gr.dart';
import '../../../event/data/services/event_api_service.dart';
import '../../../event/domain/entities/event.dart';
import '../../../event/presentation/bloc/event_bloc.dart';
import '../../../profile/presentation/pages/all_activity_history_page.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final EventBloc _eventBloc;
  String _selectedCategory = 'All';
  late Future<Map<String, List<Event>>> _myEventsFuture;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _eventBloc = sl<EventBloc>();
    _eventBloc.add(LoadEvents());
    _myEventsFuture = sl<EventApiService>().getMyEvents();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _eventBloc.close();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _eventBloc,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FF),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeroSection(),
                  const SizedBox(height: 28),
                  _buildEventStatsSection(),
                  const SizedBox(height: 24),
                  _buildLiveEventSection(),
                  const SizedBox(height: 24),
                  _buildJoinedEventsSection(),
                  const SizedBox(height: 28),
                  _buildCategoriesSection(),
                  const SizedBox(height: 8),
                  _buildNearbyTitle(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            _buildNearbyEventsList(),
            const SliverPadding(padding: EdgeInsets.only(bottom: 110)),
          ],
        ),
      ),
    );
  }

  // ─── App Bar ─────────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(color: Colors.white.withValues(alpha: 0.92)),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CURRENT LOCATION',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textHint,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'Ho Chi Minh City',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.secondary,
            size: 18,
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: AppColors.secondary),
          onPressed: () => HapticFeedback.selectionClick(),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: AppColors.secondary,
              ),
              onPressed: () => HapticFeedback.selectionClick(),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  // ─── Hero Section ─────────────────────────────────────────────────────────────
  Widget _buildHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Tonight's Vibes ✨",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: AppColors.secondary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Discover what\'s happening around you',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 310,
          child: BlocBuilder<EventBloc, EventState>(
            builder: (context, state) {
              if (state is EventLoading || state is EventInitial) {
                return _buildHeroShimmer();
              }
              if (state is EventLoaded && state.events.isNotEmpty) {
                final highlighted = state.events.take(3).toList();
                return PageView.builder(
                  controller: PageController(viewportFraction: 0.88),
                  itemCount: highlighted.length,
                  itemBuilder: (context, index) => Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 20 : 8,
                      right: index == highlighted.length - 1 ? 20 : 8,
                    ),
                    child: _buildHeroCard(highlighted[index]),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeroShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(28),
        ),
      ),
    );
  }

  Widget _buildHeroCard(Event event) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.router.push(EventDetailRoute(eventId: event.id));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                event.photoUrls.isNotEmpty
                    ? event.photoUrls.first
                    : 'https://picsum.photos/seed/${event.id}/600/400',
                fit: BoxFit.cover,
                errorBuilder: (context2, err, trace) =>
                    Container(color: AppColors.bgSecondary),
              ),
              // Gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                    stops: [0.3, 1.0],
                  ),
                ),
              ),
              // Match badge
              if (event.matchScore > 80)
                Positioned(
                  top: 16,
                  left: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '⚡ ${event.matchScore.toInt()}% MATCH',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // Bottom content
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _GlassPill(
                          '${event.categoryEmoji} ${event.categoryName}',
                        ),
                        const SizedBox(width: 8),
                        _GlassPill('📍 1.2 km'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white24,
                          backgroundImage: NetworkImage(event.hostAvatar),
                          onBackgroundImageError: (o, s) {},
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'by ${event.hostName}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            context.router.push(
                              EventDetailRoute(eventId: event.id),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Text(
                              'JOIN',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Event Stats ──────────────────────────────────────────────────────────────
  Widget _buildEventStatsSection() {
    return FutureBuilder<Map<String, List<Event>>>(
      future: _myEventsFuture,
      builder: (context, snapshot) {
        final hosting = snapshot.data?['hosting']?.length ?? 0;
        final joined = snapshot.data?['joined']?.length ?? 0;
        final past = snapshot.data?['past']?.length ?? 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1565C0),
                  Color(0xFF1E88E5),
                  Color(0xFF1CB5E0),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                // Pie chart
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          centerSpaceRadius: 26,
                          sectionsSpace: 3,
                          borderData: FlBorderData(show: false),
                          sections: [
                            PieChartSectionData(
                              value: (hosting == 0 && joined == 0 && past == 0)
                                  ? 1
                                  : hosting.toDouble(),
                              color: Colors.white,
                              radius: 22,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: joined.toDouble(),
                              color: Colors.white.withValues(alpha: 0.55),
                              radius: 22,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: past.toDouble(),
                              color: Colors.white.withValues(alpha: 0.25),
                              radius: 22,
                              showTitle: false,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${hosting + joined + past}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              height: 1,
                            ),
                          ),
                          const Text(
                            'total',
                            style: TextStyle(
                              color: Colors.white60,
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Event Stats',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _StatLegendRow('Hosting', hosting, Colors.white),
                      const SizedBox(height: 6),
                      _StatLegendRow(
                        'Joined',
                        joined,
                        Colors.white.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 6),
                      _StatLegendRow(
                        'Past',
                        past,
                        Colors.white.withValues(alpha: 0.35),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AllActivityHistoryPage(
                          initialTab: 0,
                          showPinActions: false,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Live Event Section ───────────────────────────────────────────────────────
  Widget _buildLiveEventSection() {
    return FutureBuilder<Map<String, List<Event>>>(
      future: _myEventsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final mine = [
          ...snapshot.data!['hosting'] ?? const <Event>[],
          ...snapshot.data!['joined'] ?? const <Event>[],
        ];
        final seen = <String>{};
        final ongoing = mine
            .where((e) => e.status == EventStatus.active && seen.add(e.id))
            .toList();

        if (ongoing.isEmpty) return const SizedBox.shrink();

        // Take only the FIRST (most relevant) ongoing event
        final event = ongoing.first;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // LIVE dot with pulse
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (context, _) => Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(
                              alpha: 0.3 + 0.5 * _pulseCtrl.value,
                            ),
                            blurRadius: 6 + 6 * _pulseCtrl.value,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'HAPPENING NOW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.error,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  context.router.push(EventDetailRoute(eventId: event.id));
                },
                child: _buildLiveCard(event),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveCard(Event event) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              event.photoUrls.isNotEmpty
                  ? event.photoUrls.first
                  : 'https://picsum.photos/seed/${event.id}/600/400',
              fit: BoxFit.cover,
              errorBuilder: (context2, err, trace) =>
                  Container(color: AppColors.bgSecondary),
            ),
            // Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            // LIVE badge
            Positioned(
              top: 16,
              right: 16,
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (context, _) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withValues(
                          alpha: 0.4 + 0.4 * _pulseCtrl.value,
                        ),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fiber_manual_record,
                        color: Colors.white,
                        size: 8,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      height: 1.15,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Participant stack
                      if (event.participantAvatars.isNotEmpty)
                        SizedBox(
                          height: 28,
                          width:
                              (event.participantAvatars.take(4).length * 18)
                                  .toDouble() +
                              8,
                          child: Stack(
                            children: event.participantAvatars
                                .take(4)
                                .toList()
                                .asMap()
                                .entries
                                .map(
                                  (e) => Positioned(
                                    left: e.key * 14.0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.white24,
                                        backgroundImage: NetworkImage(e.value),
                                        onBackgroundImageError: (o, s) {},
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      const SizedBox(width: 10),
                      Text(
                        '${event.currentParticipants} joined',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: AppColors.secondary,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Continue',
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Joined Events ────────────────────────────────────────────────────────────
  Widget _buildJoinedEventsSection() {
    return FutureBuilder<Map<String, List<Event>>>(
      future: _myEventsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final joined = snapshot.data!['joined'] ?? const <Event>[];
        if (joined.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Joined Vibes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AllActivityHistoryPage(
                            initialTab: 1,
                            showPinActions: false,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'View all',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: joined.take(5).length,
                separatorBuilder: (e, s) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final event = joined[index];
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.router.push(EventDetailRoute(eventId: event.id));
                    },
                    child: Container(
                      width: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(18),
                            ),
                            child: Image.network(
                              event.photoUrls.isNotEmpty
                                  ? event.photoUrls.first
                                  : 'https://picsum.photos/seed/${event.id}/120',
                              width: 80,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context2, err, trace) => Container(
                                width: 80,
                                color: AppColors.bgSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    event.categoryEmoji,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    event.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: AppColors.secondary,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Categories ───────────────────────────────────────────────────────────────
  Widget _buildCategoriesSection() {
    final cats = [
      ('All', null),
      ('Sports', '🏃'),
      ('Dining', '🍜'),
      ('Social', '💬'),
      ('Arts', '🎨'),
      ('Outdoors', '⛺'),
      ('Gaming', '🎮'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Explore',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondary,
                ),
              ),
              GestureDetector(
                onTap: () => context.router.push(const CreateEventRoute()),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Create',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            children: cats
                .map(
                  (cat) => _CategoryChip(
                    label: cat.$1,
                    emoji: cat.$2,
                    isSelected: _selectedCategory == cat.$1,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCategory = cat.$1);
                      _eventBloc.add(
                        LoadEvents(category: cat.$1 == 'All' ? null : cat.$1),
                      );
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyTitle() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Kèo Gần Đây',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: AppColors.secondary,
        ),
      ),
    );
  }

  // ─── Nearby Events ────────────────────────────────────────────────────────────
  Widget _buildNearbyEventsList() {
    return BlocBuilder<EventBloc, EventState>(
      builder: (context, state) {
        if (state is EventLoaded) {
          final events = state.events.skip(3).toList();
          if (events.isEmpty) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.explore_off_rounded,
                        size: 48,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No vibes found nearby',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _NearbyEventCard(
                event: events[index],
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.router.push(
                    EventDetailRoute(eventId: events[index].id),
                  );
                },
              ),
              childCount: events.length,
            ),
          );
        }
        return const SliverToBoxAdapter(child: SizedBox());
      },
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _GlassPill extends StatelessWidget {
  const _GlassPill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatLegendRow extends StatelessWidget {
  const _StatLegendRow(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final String? emoji;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = label == 'All'
        ? AppColors.primary
        : AppColors.getCategoryColor(label);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [catColor, catColor.withValues(alpha: 0.8)],
                )
              : LinearGradient(
                  colors: [
                    isDark ? AppColors.darkCardBackground : Colors.white,
                    isDark ? AppColors.darkCardBackground : Colors.white,
                  ],
                ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? catColor.withValues(alpha: 0.6)
                : AppColors.borderLight,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: catColor.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.secondaryMedium),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyEventCard extends StatelessWidget {
  const _NearbyEventCard({required this.event, required this.onTap});
  final Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(20),
              ),
              child: Image.network(
                event.photoUrls.isNotEmpty
                    ? event.photoUrls.first
                    : 'https://picsum.photos/seed/${event.id}/200',
                width: 92,
                height: 92,
                fit: BoxFit.cover,
                errorBuilder: (context2, err, trace) => Container(
                  width: 92,
                  height: 92,
                  color: AppColors.bgSecondary,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${event.categoryEmoji} ${event.categoryName}',
                          style: TextStyle(
                            color: AppColors.getCategoryColor(
                              event.categoryName,
                            ),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          '📍 2.5km',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Avatar stack
                        if (event.participantAvatars.isNotEmpty)
                          SizedBox(
                            height: 22,
                            width:
                                (event.participantAvatars.take(3).length * 14)
                                    .toDouble() +
                                6,
                            child: Stack(
                              children: event.participantAvatars
                                  .take(3)
                                  .toList()
                                  .asMap()
                                  .entries
                                  .map(
                                    (e) => Positioned(
                                      left: e.key * 12.0,
                                      child: CircleAvatar(
                                        radius: 10,
                                        backgroundColor: AppColors.bgSecondary,
                                        backgroundImage: NetworkImage(e.value),
                                        onBackgroundImageError: (o, s) {},
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        const SizedBox(width: 6),
                        Text(
                          '${event.currentParticipants}/${event.maxParticipants}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            event.price == null || event.price == 0
                                ? 'Free'
                                : '\$${event.price!.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
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
