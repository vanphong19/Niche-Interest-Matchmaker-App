import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:auto_route/auto_route.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/profile_state.dart';
import '../../../../core/services/signalr_service.dart';
import '../../../profile/data/services/user_api_service.dart';
import '../../../../injection/injection_container.dart';
import '../../../../router/app_router.gr.dart';
import '../../../event/domain/entities/event.dart';
import '../../../event/presentation/bloc/event_bloc.dart';
import '../../../../core/widgets/vibe_header.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../chat/presentation/pages/chat_inbox_page.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final EventBloc _eventBloc;
  late final PageController _heroPageController;
  late AnimationController _pulseCtrl;
  final List<StreamSubscription<Map<String, dynamic>>> _subscriptions = [];
  Timer? _reloadDebounce;
  bool _hasResolvedFirstHeroLoad = false;

  @override
  void initState() {
    super.initState();
    _eventBloc = sl<EventBloc>();
    _heroPageController = PageController(viewportFraction: 0.92);
    _eventBloc.add(LoadEvents(category: _eventBloc.state.selectedCategory));
    _loadProfile();
    final signalR = sl<SignalRService>();
    _subscriptions.addAll([
      signalR.eventStatusStream.listen((_) => _reload()),
      signalR.matchStream.listen((_) => _reload()),
    ]);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _reloadDebounce?.cancel();
    _heroPageController.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await sl<UserApiService>().getProfile();
      ProfileState.updateProfile(profile);
    } catch (_) {}
  }

  void _reload() {
    if (!mounted) return;
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _eventBloc.add(LoadEvents(category: _eventBloc.state.selectedCategory));
      _loadProfile();
    });
  }

  void _openMapDiscovery() {
    HapticFeedback.selectionClick();
    context.router.push(const MapDiscoveryRoute());
  }

  void _openFindInCrowd() {
    HapticFeedback.selectionClick();
    context.router.push(const FindInCrowdMeetingRoute());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _eventBloc,
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkBgPrimary
            : const Color(0xFFF5F7FF),
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
                  const SizedBox(height: 18),
                  _buildHeroSection(),
                  const SizedBox(height: 16),
                  _buildChatBanner(),
                  const SizedBox(height: 16),
                  _buildExploreMapBanner(),
                  const SizedBox(height: 12),
                  _buildFindInCrowdBanner(),
                  const SizedBox(height: 16),
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
              alpha: 0.52,
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
          onTap: _openMapDiscovery,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: isDark
                      ? [
                          Colors.white,
                          const Color(0xFF93C5FD),
                          const Color(0xFF60A5FA),
                        ]
                      : [
                          AppColors.secondary,
                          const Color(0xFF1E40AF),
                          const Color(0xFF2563EB),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Text(
                  "My Vibes",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                ).createShader(bounds),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 19,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              BlocBuilder<EventBloc, EventState>(
                builder: (context, state) {
                  final count = state.joined.length;
                  if (count == 0) return const SizedBox.shrink();
                  return AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4.5,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(
                              alpha: 0.12 + (_pulseCtrl.value * 0.08),
                            ),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withValues(
                                      alpha: 0.4 + (_pulseCtrl.value * 0.4),
                                    ),
                                    blurRadius: 4 + (_pulseCtrl.value * 4),
                                    spreadRadius: _pulseCtrl.value * 1.5,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${count.toString()} LIVE',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        _buildCategoryFilter(),
        const SizedBox(height: 10),
        SizedBox(
          height: 240, // Increased to avoid overflow with empty state
          child: ValueListenableBuilder<ProfileData>(
            valueListenable: ProfileState.notifier,
            builder: (context, profile, child) {
              return BlocBuilder<EventBloc, EventState>(
                builder: (context, state) {
                  final List<Event> displayEvents =
                      state.selectedCategory != null
                      ? state.joined
                            .where(
                              (e) =>
                                  e.category.name.toLowerCase() ==
                                  state.selectedCategory!.toLowerCase(),
                            )
                            .toList()
                      : state.joined;

                  if (!state.isLoading) {
                    _hasResolvedFirstHeroLoad = true;
                  }

                  if (state.isLoading &&
                      state.events.isEmpty &&
                      !_hasResolvedFirstHeroLoad) {
                    return _buildHeroShimmer();
                  }

                  if (displayEvents.isNotEmpty) {
                    final highlighted = displayEvents.take(5).toList();
                    return _buildHeroCarousel(
                      highlighted,
                      state,
                      showOverlay: state.isLoading,
                    );
                  }

                  if (state.isLoading) {
                    return Stack(
                      children: [
                        _buildEmptyState(),
                        _buildHeroLoadingOverlay(),
                      ],
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

  // ignore: unused_element
  List<Event> _buildAllHeroEvents(EventState state) {
    final profileId = ProfileState.notifier.value.id;
    final visibleFromFeed = state.events.where((event) {
      return event.isJoined || _isHostedEvent(event, state, profileId);
    }).toList();

    return _mergeUniqueEvents([
      ...visibleFromFeed,
      ...state.hosting,
      ...state.joined,
    ]);
  }

  bool _isHostedEvent(Event event, EventState state, String profileId) {
    final hostId = event.hostId.toLowerCase();
    return (profileId.isNotEmpty && hostId == profileId.toLowerCase()) ||
        state.hosting.any((hosted) => hosted.id == event.id);
  }

  List<Event> _mergeUniqueEvents(List<Event> events) {
    final seen = <String>{};
    final merged = <Event>[];
    for (final event in events) {
      if (event.id.isEmpty || !seen.add(event.id)) continue;
      merged.add(event);
    }
    return merged;
  }

  void _resetHeroCarousel() {
    if (!_heroPageController.hasClients) return;
    _heroPageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildHeroShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  Widget _buildHeroCarousel(
    List<Event> highlighted,
    EventState state, {
    required bool showOverlay,
  }) {
    return Stack(
      children: [
        PageView.builder(
          controller: _heroPageController,
          itemCount: highlighted.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildHeroCard(highlighted[index], state),
                if (showOverlay) _buildHeroCardLoadingScrim(),
              ],
            ),
          ),
        ),
        if (showOverlay) _buildHeroLoadingPill(),
      ],
    );
  }

  Widget _buildHeroCardLoadingScrim() {
    return Positioned.fill(
      child: IgnorePointer(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(color: Colors.black.withValues(alpha: 0.12)),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroLoadingPill() {
    return Positioned.fill(
      child: IgnorePointer(child: Center(child: _buildUpdatingVibesPill())),
    );
  }

  Widget _buildHeroLoadingOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                alignment: Alignment.center,
                color: Colors.black.withValues(alpha: 0.12),
                child: _buildUpdatingVibesPill(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpdatingVibesPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF111827).withValues(alpha: 0.88)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Updating vibes',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppColors.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(Event event, EventState state) {
    final profile = ProfileState.notifier.value;
    final isHosting = _isHostedEvent(event, state, profile.id);
    final isJoined =
        event.isJoined || state.joined.any((e) => e.id == event.id);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.router.push(EventDetailRoute(eventId: event.id));
      },
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                event.photoUrls.isNotEmpty
                    ? event.photoUrls.first
                    : 'https://api-prod-minimal-v700.pages.dev/assets/images/cover/cover-${(event.id.hashCode % 20) + 1}.webp',
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
                        VibeAvatar(
                          imageUrl: event.hostAvatar,
                          name: event.hostName,
                          size: 32,
                          showBorder: false,
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
    return ValueListenableBuilder<ProfileData>(
      valueListenable: ProfileState.notifier,
      builder: (context, profile, child) {
        final hostingCount = profile.hostedCount;
        final attendingCount = profile.attendingCount;
        final pastCount = profile.pastCount;

        final totalDisplayCount = attendingCount + pastCount;

        final colorList = [
          const Color(0xFF3B82F6), // Hosted: Premium Blue
          const Color(0xFF64748B), // Attending/Joined: Emerald Green
          const Color(0xFF10B981), // Past: Elegant Slate
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
                                              attendingCount.toDouble() == 0 &&
                                              pastCount.toDouble() == 0
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
                                'Hosted',
                                hostingCount,
                                colorList[0],
                              ),
                              const SizedBox(height: 10),
                              _StatLegendRow(
                                'Attending',
                                attendingCount,
                                colorList[1],
                              ),
                              const SizedBox(height: 10),
                              _StatLegendRow('Past', pastCount, colorList[2]),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, child) {
          return _HomeEmptyState(progress: _pulseCtrl.value);
        },
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
      {'id': 'outdoor', 'name': 'Outdoors', 'emoji': '⛺'},
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
                      _resetHeroCarousel();
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

  Widget _buildExploreMapBanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _InteractiveMapBanner(onTap: _openMapDiscovery, isDark: isDark),
    );
  }

  Widget _buildChatBanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    void openChat() {
      HapticFeedback.selectionClick();
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const ChatInboxPage()));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _ChatBanner(onTap: openChat, isDark: isDark),
    );
  }

  Widget _buildFindInCrowdBanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _openFindInCrowd,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF10233A), const Color(0xFF0F172A)]
                  : [Colors.white, const Color(0xFFEAF6FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.primary.withValues(alpha: 0.16),
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.radar_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find In Crowd',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.secondary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Open GPS finder flow and locate your meetup partner',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: isDark ? Colors.white70 : AppColors.primary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

// ─── Chat Banner ──────────────────────────────────────────────────────────────

class _ChatBanner extends StatefulWidget {
  const _ChatBanner({required this.onTap, required this.isDark});
  final VoidCallback onTap;
  final bool isDark;

  @override
  State<_ChatBanner> createState() => _ChatBannerState();
}

class _ChatBannerState extends State<_ChatBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          height: 130,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: widget.isDark
                ? LinearGradient(
                    colors: [
                      const Color(0xFF172554).withValues(alpha: 0.95),
                      const Color(0xFF0F172A).withValues(alpha: 0.98),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [
                      Color(0xFF1565C0),
                      Color(0xFF1E88E5),
                      Color(0xFF42A5F5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            border: Border.all(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.15),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: widget.isDark ? 0.2 : 0.3,
                ),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Abstract chat bubbles background art
              Positioned(
                right: -10,
                bottom: -20,
                top: -20,
                width: 160,
                child: CustomPaint(
                  painter: _ChatBgPainter(isDark: widget.isDark),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_rounded,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'MESSAGES',
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.0,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Unread badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '11 chưa đọc',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Nhóm Chat & Tin nhắn',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Chat nhóm sự kiện & nhắn tin riêng',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Open button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.mark_chat_unread_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Mở',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
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
}

class _ChatBgPainter extends CustomPainter {
  _ChatBgPainter({required this.isDark});
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.08);

    // Draw chat bubble shapes
    final rRect1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.15, size.height * 0.1, 90, 36),
      const Radius.circular(18),
    );
    canvas.drawRRect(rRect1, paint);

    final rRect2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.32, size.height * 0.42, 70, 28),
      const Radius.circular(14),
    );
    canvas.drawRRect(
      rRect2,
      paint..color = Colors.white.withValues(alpha: 0.06),
    );

    final rRect3 = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.08, size.height * 0.62, 100, 32),
      const Radius.circular(16),
    );
    canvas.drawRRect(
      rRect3,
      paint..color = Colors.white.withValues(alpha: 0.05),
    );

    // Dot indicators (like message dots)
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.25 + i * 16, size.height * 0.78),
        5,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Map Banner ───────────────────────────────────────────────────────────────

class _InteractiveMapBanner extends StatefulWidget {
  const _InteractiveMapBanner({required this.onTap, required this.isDark});
  final VoidCallback onTap;
  final bool isDark;

  @override
  State<_InteractiveMapBanner> createState() => _InteractiveMapBannerState();
}

class _InteractiveMapBannerState extends State<_InteractiveMapBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          height: 130,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: widget.isDark
                ? LinearGradient(
                    colors: [
                      const Color(0xFF1E293B).withValues(alpha: 0.95),
                      const Color(0xFF0F172A).withValues(alpha: 0.95),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Colors.white, Color(0xFFEEF2F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            border: Border.all(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFCBD5E1).withValues(alpha: 0.6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : const Color(0xFF1E293B).withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Abstract neon grid/map art in the background (Right side)
              Positioned(
                right: -20,
                bottom: -30,
                top: -30,
                width: 180,
                child: CustomPaint(
                  painter: _AbstractMapBgPainter(isDark: widget.isDark),
                ),
              ),

              // Text Content & Action Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.explore_rounded,
                                      size: 11,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'DISCOVER',
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.0,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Explore Nearby Vibes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: widget.isDark
                                  ? Colors.white
                                  : AppColors.secondary,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Find public events & activities on an interactive map',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: widget.isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Glassmorphic Map Pill on the right
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: widget.isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: widget.isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFFCBD5E1),
                          width: 1,
                        ),
                        boxShadow: [
                          if (!widget.isDark)
                            BoxShadow(
                              color: const Color(
                                0xFF1C2C58,
                              ).withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.map_rounded,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Map',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: widget.isDark
                                  ? Colors.white
                                  : AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
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
}

class _AbstractMapBgPainter extends CustomPainter {
  _AbstractMapBgPainter({required this.isDark});
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.7, size.height * 0.5);
    final paintLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.05)
          : AppColors.primary.withValues(alpha: 0.08);

    // Draw grid rings
    canvas.drawCircle(center, 40, paintLine);
    canvas.drawCircle(center, 70, paintLine);
    canvas.drawCircle(center, 100, paintLine);

    // Draw a curved route trail
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.9)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.8,
        center.dx,
        center.dy,
      );

    canvas.drawPath(
      path,
      paintLine
        ..strokeWidth = 2.0
        ..color = isDark
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.primary.withValues(alpha: 0.12),
    );

    // Draw some connection dots
    final paintDot = Paint()
      ..color = isDark
          ? AppColors.primary.withValues(alpha: 0.2)
          : AppColors.primary.withValues(alpha: 0.15);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.9), 4, paintDot);
    canvas.drawCircle(
      Offset(size.width * 0.32, size.height * 0.83),
      3,
      paintDot,
    );

    // Draw glowing pulsing location circle at center
    final paintPulse = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 12, paintPulse);

    // Draw modern location marker
    final paintPin = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6, paintPin);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HomeEmptyState extends StatelessWidget {
  const _HomeEmptyState({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pulse = 0.94 + (progress * 0.08);

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.borderLight,
          width: 1.2,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(92),
                  painter: _EmptyOrbitPainter(
                    progress: progress,
                    isDark: isDark,
                  ),
                ),
                Transform.scale(
                  scale: pulse,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 20,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Transform.rotate(
                      angle: progress * math.pi * 0.16,
                      child: const Icon(
                        Icons.explore_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'No Vibes Found',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.secondary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nothing is live here yet. Try another category or check back soon.',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyOrbitPainter extends CustomPainter {
  const _EmptyOrbitPainter({required this.progress, required this.isDark});

  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final baseColor = isDark ? Colors.white : AppColors.primary;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = baseColor.withValues(alpha: isDark ? 0.12 : 0.16);

    canvas.drawCircle(center, 42, ringPaint);
    canvas.drawCircle(
      center,
      31,
      ringPaint..color = baseColor.withValues(alpha: 0.09),
    );

    final dotPaint = Paint()..color = AppColors.success;
    for (var i = 0; i < 3; i++) {
      final angle = (progress * math.pi * 2) + (i * math.pi * 2 / 3);
      final radius = i == 0 ? 42.0 : 31.0;
      final position = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      canvas.drawCircle(position, i == 0 ? 3.5 : 2.8, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EmptyOrbitPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}

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
