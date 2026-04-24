// lib/features/profile/presentation/pages/profile_page.dart
import 'dart:ui';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../core/utils/profile_state.dart';
import '../../../../injection/injection_container.dart';
import '../../../../router/app_router.gr.dart';
import '../../../event/data/services/event_api_service.dart';
import '../../../event/domain/entities/event.dart';
import 'all_activity_history_page.dart';

@RoutePage()
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _headerFade;
  late Animation<Offset> _statsSlide;
  late Animation<double> _sectionsFade;
  List<Event> _joinedEvents = const [];
  List<Event> _pastEvents = const [];
  bool _historyLoading = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _statsSlide =
        Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _sectionsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
      ),
    );
    _animController.forward();
    _loadMyEvents();
  }

  Future<void> _loadMyEvents() async {
    final result = await sl<EventApiService>().getMyEvents();
    if (!mounted) return;
    setState(() {
      _joinedEvents = result['joined'] ?? const [];
      _pastEvents = result['past'] ?? const [];
      _historyLoading = false;
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.darkBgPrimary : const Color(0xFFF5F7FF);

    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.localeNotifier,
      builder: (context, locale, child) {
        return ValueListenableBuilder<ProfileData>(
          valueListenable: ProfileState.notifier,
          builder: (context, profileData, _) {
            return Scaffold(
              backgroundColor: bgColor,
              body: SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 16, 20, 110),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FadeTransition(
                              opacity: _headerFade,
                              child: _buildTopBar(isDark, profileData),
                            ),
                            const SizedBox(height: 24),
                            FadeTransition(
                              opacity: _headerFade,
                              child: _buildProfileHeader(isDark, profileData),
                            ),
                            const SizedBox(height: 24),
                            SlideTransition(
                              position: _statsSlide,
                              child: FadeTransition(
                                opacity: _headerFade,
                                child: _buildStatsRow(isDark),
                              ),
                            ),
                            const SizedBox(height: 28),
                            FadeTransition(
                              opacity: _sectionsFade,
                              child: _buildInterestsSection(
                                  isDark, profileData),
                            ),
                            const SizedBox(height: 28),
                            FadeTransition(
                              opacity: _sectionsFade,
                              child: _buildBadgesSection(isDark),
                            ),
                            const SizedBox(height: 28),
                            FadeTransition(
                              opacity: _sectionsFade,
                              child: _buildActivitySection(isDark),
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
        );
      },
    );
  }

  // ─── Top bar ────────────────────────────────────────
  Widget _buildTopBar(bool isDark, ProfileData profile) {
    return Row(
      children: [
        Row(
          children: [
            Icon(Icons.location_on_rounded,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 5),
            Text(
              profile.location.isNotEmpty
                  ? profile.location
                  : 'Ho Chi Minh City',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.secondary,
              ),
            ),
          ],
        ),
        const Spacer(),
        _HeaderIcon(
          icon: Icons.notifications_none_rounded,
          isDark: isDark,
        ),
        const SizedBox(width: 8),
        _HeaderIcon(
          icon: Icons.settings_outlined,
          isDark: isDark,
          onTap: () => context.router.push(const SettingsRoute()),
        ),
      ],
    );
  }

  // ─── Profile header ─────────────────────────────────
  Widget _buildProfileHeader(bool isDark, ProfileData profile) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF1C2C58);

    return Column(
      children: [
        // Avatar
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: VibeAvatar(
                  imageUrl: profile.avatarUrl,
                  name: profile.name,
                  size: 104,
                  showBorder: false,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 4,
              child: GestureDetector(
                onTap: () => context.router.push(const EditProfileRoute()),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBgPrimary
                          : const Color(0xFFF5F7FF),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.edit_rounded,
                      color: Colors.white, size: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          profile.name,
          style: AppTextStyles.headingLarge.copyWith(
            fontSize: 28,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '@${profile.username}',
          style: TextStyle(
            color: AppColors.textHint,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            profile.bio,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
              fontSize: 14,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Reputation pill – premium gold
        _ReputationBadge(),
      ],
    );
  }

  // ─── Stats row ──────────────────────────────────────
  Widget _buildStatsRow(bool isDark) {
    final cardBg = isDark ? AppColors.darkCardBackground : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatChip(value: '12', label: 'Created', isDark: isDark),
          _StatDivider(),
          _StatChip(value: '34', label: 'Joined', isDark: isDark),
          _StatDivider(),
          _StatChip(value: '156', label: 'Friends', isDark: isDark),
          _StatDivider(),
          _StatChip(value: '8', label: 'Badges', isDark: isDark),
        ],
      ),
    );
  }

  // ─── Interests section ──────────────────────────────
  Widget _buildInterestsSection(bool isDark, ProfileData profile) {
    final selected = profile.interests
        .where((i) => i['selected'] == true)
        .toList();
    if (selected.isEmpty) return const SizedBox.shrink();

    final textPrimary =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF1C2C58);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.tr('interests'),
              style: AppTextStyles.headingSmall.copyWith(color: textPrimary),
            ),
            const SizedBox(width: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${selected.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: selected.map((interest) {
            final name = interest['name'] as String;
            final icon = _getIcon(interest['icon'] as String);
            final color = AppColors.getCategoryColor(name);

            return _InterestPill(
              name: name,
              icon: icon,
              color: color,
              isDark: isDark,
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Badges section ─────────────────────────────────
  Widget _buildBadgesSection(bool isDark) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF1C2C58);

    final badges = [
      _BadgeData(
        icon: Icons.military_tech_rounded,
        name: 'Top Host',
        gradient: const [Color(0xFF4884C9), Color(0xFF306DB9)],
        isUnlocked: true,
        desc: '5+ events hosted',
      ),
      _BadgeData(
        icon: Icons.bolt_rounded,
        name: 'Always On Time',
        gradient: const [Color(0xFFF3B541), Color(0xFFFAA320)],
        isUnlocked: true,
        desc: '10 on-time joins',
      ),
      _BadgeData(
        icon: Icons.people_alt_rounded,
        name: 'Social Butterfly',
        gradient: const [Color(0xFF4CB098), Color(0xFF1DA187)],
        isUnlocked: true,
        desc: '20+ connections',
      ),
      _BadgeData(
        icon: Icons.explore_rounded,
        name: 'Explorer',
        gradient: const [Color(0xFF6D48BD), Color(0xFF4E2D95)],
        isUnlocked: true,
        desc: '5 categories',
      ),
      _BadgeData(
        icon: Icons.emoji_events_rounded,
        name: 'Champion',
        gradient: const [Color(0xFFC65050), Color(0xFFB02D2D)],
        isUnlocked: true,
        desc: 'Top rated host',
      ),
      _BadgeData(
        icon: Icons.local_fire_department_rounded,
        name: 'Streak Master',
        gradient: const [Color(0xFF444444), Color(0xFF222222)],
        isUnlocked: false,
        desc: '7-day streak',
      ),
      _BadgeData(
        icon: Icons.auto_graph_rounded,
        name: 'Growth Aura',
        gradient: const [Color(0xFF5197E0), Color(0xFF356FDB)],
        isUnlocked: true,
        desc: 'Rising star',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.tr('badges_gallery'),
              style:
                  AppTextStyles.headingSmall.copyWith(color: textPrimary),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${badges.where((b) => b.isUnlocked).length} unlocked',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 172,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: const BouncingScrollPhysics(),
            itemCount: badges.length,
            separatorBuilder: (e, s) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _BadgeCard(data: badges[index]);
            },
          ),
        ),
      ],
    );
  }

  // ─── Activity section ───────────────────────────────
  Widget _buildActivitySection(bool isDark) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF1C2C58);
    final allParticipated = [..._joinedEvents, ..._pastEvents];

    return ValueListenableBuilder<Set<String>>(
      valueListenable: ProfileState.pinnedEventIdsNotifier,
      builder: (context, pinnedIds, _) {
        final pinned = allParticipated
            .where((e) => pinnedIds.contains(e.id))
            .toList();
        final featured = pinned.isNotEmpty ? pinned.first : null;
        final rest = pinned.skip(1).take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.tr('activity_history'),
                  style: AppTextStyles.headingSmall
                      .copyWith(color: textPrimary),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AllActivityHistoryPage(
                          initialTab: 1,
                          showPinActions: true,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLocalizations.tr('view_all'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            size: 10, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_historyLoading)
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A2232)
                      : AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(16),
                ),
              )
            else if (pinned.isEmpty)
              _buildPinPrompt(isDark)
            else ...[
              if (featured != null)
                GestureDetector(
                  onTap: () => context.router.push(
                    EventDetailRoute(eventId: featured.id),
                  ),
                  child: _buildFeaturedActivity(featured, isDark),
                ),
              if (rest.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 116,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: rest.length,
                    separatorBuilder: (e, s) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final event = rest[index];
                      return GestureDetector(
                        onTap: () => context.router.push(
                          EventDetailRoute(eventId: event.id),
                        ),
                        child: SizedBox(
                          width: 200,
                          child: _buildMiniActivity(event),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  Widget _buildPinPrompt(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2232) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.push_pin_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pin events to show here',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Tap "View all" → pin events to show on your profile',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedActivity(Event event, bool isDark) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              event.photoUrls.isNotEmpty
                  ? event.photoUrls.first
                  : 'https://picsum.photos/seed/${event.id}/900/500',
              fit: BoxFit.cover,
              errorBuilder: (e, s, t) =>
                  Container(color: AppColors.bgSecondary),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                  stops: [0.35, 1.0],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 14,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    color: Colors.white.withValues(alpha: 0.25),
                    child: Text(
                      '📌 Pinned',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 14,
              left: 16,
              right: 16,
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
                      fontSize: 20,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.people_rounded,
                          color: Colors.white70, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        '${event.currentParticipants} participants',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.location_on_rounded,
                          color: Colors.white70, size: 13),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
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
    );
  }

  Widget _buildMiniActivity(Event event) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            event.photoUrls.isNotEmpty
                ? event.photoUrls.first
                : 'https://picsum.photos/seed/${event.id}/400',
            fit: BoxFit.cover,
            errorBuilder: (e, s, t) =>
                Container(color: AppColors.bgSecondary),
          ),
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
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${event.startDateTime.day}/${event.startDateTime.month}/${event.startDateTime.year}',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helper ─────────────────────────────────────────
  static IconData _getIcon(String name) {
    switch (name) {
      case 'sports_basketball':
        return Icons.sports_basketball;
      case 'music_note':
        return Icons.music_note;
      case 'computer':
        return Icons.computer;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'restaurant':
        return Icons.restaurant;
      case 'palette':
        return Icons.palette;
      case 'terrain':
        return Icons.terrain;
      case 'people':
        return Icons.people;
      case 'camera_alt':
        return Icons.camera_alt;
      case 'flight':
        return Icons.flight;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'movie':
        return Icons.movie;
      default:
        return Icons.local_activity;
    }
  }
}

// ─── Reputation Badge ─────────────────────────────────────────────────────────
class _ReputationBadge extends StatelessWidget {
  const _ReputationBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA000), Color(0xFFFF8F00)],
          stops: [0.0, 0.5, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'REPUTATION',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.8),
                  letterSpacing: 1.5,
                  fontSize: 9,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '982',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 26,
                  letterSpacing: -0.5,
                  height: 1,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Interest Pill ────────────────────────────────────────────────────────────
class _InterestPill extends StatelessWidget {
  const _InterestPill({
    required this.name,
    required this.icon,
    required this.color,
    required this.isDark,
  });
  final String name;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [color.withValues(alpha: 0.22), const Color(0xFF1B2232)]
              : [color.withValues(alpha: 0.14), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.35 : 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.14 : 0.09),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isDark
                  ? color.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 9),
          Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : color.withValues(alpha: 0.85),
              fontSize: 13,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 7),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ],
      ),
    );
  }
}

// ─── Badge Data ────────────────────────────────────────────────────────────────
class _BadgeData {
  const _BadgeData({
    required this.icon,
    required this.name,
    required this.gradient,
    required this.isUnlocked,
    required this.desc,
  });
  final IconData icon;
  final String name;
  final List<Color> gradient;
  final bool isUnlocked;
  final String desc;
}

// ─── Badge Card ───────────────────────────────────────────────────────────────
class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.data});
  final _BadgeData data;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = data.isUnlocked ? data.gradient.first : const Color(0xFF5A5A5A);

    return Container(
      width: 130,
      height: 168,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: data.isUnlocked
            ? [
                BoxShadow(
                  color: primary.withValues(alpha: isDark ? 0.28 : 0.14),
                  blurRadius: 22,
                  offset: const Offset(0, 6),
                  spreadRadius: -3,
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: data.isUnlocked
                    ? [
                        data.gradient.first
                            .withValues(alpha: isDark ? 0.88 : 0.96),
                        data.gradient.last
                            .withValues(alpha: isDark ? 0.78 : 0.92),
                      ]
                    : [
                        const Color(0xFF3A3A3A),
                        const Color(0xFF222222),
                      ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(
                    alpha: data.isUnlocked ? 0.35 : 0.15),
                width: 1.2,
              ),
            ),
            child: Stack(
              children: [
                // Glow highlight
                if (data.isUnlocked)
                  Positioned(
                    top: -48,
                    right: -48,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.22),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon circle
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(
                              alpha: data.isUnlocked ? 0.22 : 0.1),
                          border: Border.all(
                            color: Colors.white.withValues(
                                alpha: data.isUnlocked ? 0.45 : 0.2),
                            width: 1.5,
                          ),
                          boxShadow: data.isUnlocked
                              ? [
                                  BoxShadow(
                                    color: Colors.white
                                        .withValues(alpha: 0.18),
                                    blurRadius: 14,
                                  ),
                                ]
                              : [],
                        ),
                        child: Icon(
                          data.icon,
                          color: Colors.white.withValues(
                              alpha: data.isUnlocked ? 1.0 : 0.4),
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        data.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white.withValues(
                              alpha: data.isUnlocked ? 1.0 : 0.5),
                          height: 1.15,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (!data.isUnlocked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_rounded,
                                  size: 10,
                                  color: Colors.white
                                      .withValues(alpha: 0.45)),
                              const SizedBox(width: 4),
                              Text(
                                'LOCKED',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white
                                      .withValues(alpha: 0.45),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          data.desc,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.65),
                            letterSpacing: 0.2,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Stat Chip ────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.value,
    required this.label,
    required this.isDark,
  });
  final String value;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textHint,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      width: 1,
      color: AppColors.borderLight,
    );
  }
}

// ─── Header Icon ──────────────────────────────────────────────────────────────
class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.icon,
    required this.isDark,
    this.onTap,
  });
  final IconData icon;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
    );
  }
}
