import 'dart:ui';
import 'package:auto_route/auto_route.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/utils/profile_state.dart';
import '../../../../injection/injection_container.dart';
import '../../../../router/app_router.gr.dart';
import '../../../event/domain/entities/event.dart';
import '../../../event/presentation/bloc/event_bloc.dart';
import '../../../../core/widgets/vibe_header.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final EventBloc _eventBloc;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _eventBloc = sl<EventBloc>();
    _eventBloc.add(LoadEvents(category: _eventBloc.state.selectedCategory));
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
            // Removed nearby list as requested
            const SliverPadding(padding: EdgeInsets.only(bottom: 110)),
          ],
        ),
      ),
    );
  }

  // ─── App Bar ─────────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusBrightness = isDark ? Brightness.light : Brightness.dark;

    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: VibeHeader.headerHeight,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: statusBrightness,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: (isDark ? const Color(0xFF0E121A) : Colors.white).withValues(
              alpha: 0.82,
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          const SizedBox(width: 20),
          VibeHeaderButton(
            icon: Icons.location_on_rounded,
            onTap: () => HapticFeedback.mediumImpact(),
            isDark: isDark,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 5,
              children: [
                Text(
                  'CURRENT LOCATION',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textHint,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Ho Chi Minh City',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        VibeHeaderButton(
          icon: Icons.search_rounded,
          onTap: () => HapticFeedback.selectionClick(),
          isDark: isDark,
        ),
        const SizedBox(width: 8),
        Stack(
          alignment: Alignment.center,
          children: [
            VibeHeaderButton(
              icon: Icons.notifications_outlined,
              onTap: () => HapticFeedback.selectionClick(),
              isDark: isDark,
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF0E121A) : Colors.white,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  // ─── Hero Section ─────────────────────────────────────────────────────────────
  Widget _buildHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Tonight's Vibes ✨",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppColors.secondary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Discover what\'s happening around you',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildCategoryFilter(),
        const SizedBox(height: 16),
        SizedBox(
          height: 230,
          child: ValueListenableBuilder<ProfileData>(
            valueListenable: ProfileState.notifier,
            builder: (context, profile, child) {
              return BlocBuilder<EventBloc, EventState>(
                builder: (context, state) {
                  if (state.isLoading && state.events.isEmpty) {
                    return _buildHeroShimmer();
                  }
                  if (state.events.isNotEmpty) {
                    final highlighted = state.events.take(3).toList();
                    return PageView.builder(
                      controller: PageController(viewportFraction: 0.92),
                      itemCount: highlighted.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _buildHeroCard(highlighted[index], state),
                      ),
                    );
                  }
                  if (!state.isLoading) {
                    return _buildEmptyState();
                  }
                  return const SizedBox();
                },
              );
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

  Widget _buildHeroCard(Event event, EventState state) {
    final profile = ProfileState.notifier.value;
    final isHosting =
        profile.id.isNotEmpty &&
        event.hostId.toLowerCase() == profile.id.toLowerCase();
    final isJoined = state.joined.any((e) => e.id == event.id);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.router.push(EventDetailRoute(eventId: event.id));
      },
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(28)),
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
                              color: isHosting
                                  ? const Color.fromARGB(
                                      255,
                                      14,
                                      178,
                                      107,
                                    ) // Amber for Manage
                                  : (isJoined
                                        ? Colors.white.withValues(alpha: 0.15)
                                        : AppColors.primary),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              isHosting
                                  ? 'MANAGE'
                                  : (isJoined ? 'LEAVE' : 'JOIN'),
                              style: const TextStyle(
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
    return BlocBuilder<EventBloc, EventState>(
      builder: (context, state) {
        final hostingCount = state.hosting.length;
        // Attending segment only shows events joined from OTHERS
        final attendingCount = state.joined
            .where((e) => !state.hosting.any((h) => h.id == e.id))
            .length;
        final pastCount = state.past.length;

        final totalDisplayCount = hostingCount + attendingCount + pastCount;

        // Use a set of IDs to get true total unique events

        final colorList = [
          const Color(0xFF10B981), // Attending: Emerald Green
          const Color(0xFF3B82F6), // Hosting: Premium Blue
          const Color(0xFF64748B), // Past: Elegant Slate
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(
                        0xFF1E293B,
                      ).withValues(alpha: 0.98), // Midnight Slate
                      const Color(
                        0xFF0F172A,
                      ).withValues(alpha: 0.95), // Deep Navy
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1.2,
                  ),
                ),
                child: Stack(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 104,
                          height: 104,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PieChart(
                                PieChartData(
                                  centerSpaceRadius: 28,
                                  sectionsSpace: 4,
                                  borderData: FlBorderData(show: false),
                                  sections: [
                                    PieChartSectionData(
                                      value:
                                          hostingCount.toDouble() == 0 &&
                                              totalDisplayCount == 0
                                          ? 1
                                          : hostingCount.toDouble(),
                                      color: colorList[0],
                                      radius: 20,
                                      showTitle: false,
                                    ),
                                    PieChartSectionData(
                                      value: attendingCount.toDouble(),
                                      color: colorList[1],
                                      radius: 20,
                                      showTitle: false,
                                    ),
                                    PieChartSectionData(
                                      value: pastCount.toDouble(),
                                      color: colorList[2],
                                      radius: 20,
                                      showTitle: false,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    totalDisplayCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      height: 1,
                                    ),
                                  ),
                                  Text(
                                    'VIBES',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 9,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'My Stats',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _StatLegendRow(
                                AppLocalizations.tr('hosting'),
                                hostingCount,
                                colorList[0],
                              ),
                              const SizedBox(height: 10),
                              _StatLegendRow(
                                AppLocalizations.tr('joined'),
                                state.joined.length,
                                colorList[1],
                              ),
                              const SizedBox(height: 10),
                              _StatLegendRow(
                                AppLocalizations.tr('past'),
                                pastCount,
                                colorList[2],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: IconButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          context.router.push(AllActivityHistoryRoute());
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.borderLight.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.explore_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Vibes Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Be the first to start a vibe in this category or check back later!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [
      {'id': null, 'name': 'All', 'emoji': '✨'},
      {'id': 'social', 'name': 'Social', 'emoji': '💬'},
      {'id': 'dining', 'name': 'Dining', 'emoji': '🍜'},
      {'id': 'sports', 'name': 'Sports', 'emoji': '🏃'},
      {'id': 'arts', 'name': 'Arts', 'emoji': '🎨'},
      {'id': 'gaming', 'name': 'Gaming', 'emoji': '🎮'},
      {'id': 'outdoors', 'name': 'Outdoors', 'emoji': '⛺'},
    ];

    return BlocBuilder<EventBloc, EventState>(
      builder: (context, state) {
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: categories.map((cat) {
                final isSelected = state.selectedCategory == cat['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _eventBloc.add(LoadEvents(category: cat['id']));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : AppColors.borderLight.withValues(
                                        alpha: 0.5,
                                      )),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            cat['emoji'] as String,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat['name'] as String,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.secondary),
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
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
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
