// lib/features/profile/presentation/pages/profile_page.dart
import 'dart:async';
import 'dart:ui';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../core/widgets/vibe_empty_state.dart';
import '../../../../core/utils/profile_state.dart';
import '../../../../core/services/signalr_service.dart';
import '../../../../injection/injection_container.dart';
import '../../../../router/app_router.gr.dart';
import '../../../event/data/services/event_api_service.dart';
import '../../../event/domain/entities/event.dart';
import '../../data/services/user_api_service.dart';
import '../../../../core/widgets/vibe_header.dart';
import '../../../trust/domain/services/reputation_service.dart';
import '../../../trust/presentation/pages/trust_dashboard_page.dart';
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
  StreamSubscription<Map<String, dynamic>>? _realtimeSubscription;

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
    _statsSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(
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
    _loadProfile();
    _realtimeSubscription = sl<SignalRService>().dataChangeStream.listen((_) {
      _loadProfile();
      _loadMyEvents();
    });
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await sl<UserApiService>().getProfile();
      ProfileState.updateProfile(profile);
    } catch (_) {}
  }

  Future<void> _loadMyEvents() async {
    try {
      final result = await sl<EventApiService>().getMyEvents();
      if (!mounted) return;
      setState(() {
        _joinedEvents = result['joined'] ?? const [];
        _pastEvents = result['past'] ?? const [];
        _historyLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _animController.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBgPrimary : const Color(0xFFF5F7FF);

    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.localeNotifier,
      builder: (context, locale, child) {
        return ValueListenableBuilder<ProfileData>(
          valueListenable: ProfileState.notifier,
          builder: (context, profileData, _) {
            return Scaffold(
              backgroundColor: bgColor,
              extendBodyBehindAppBar: true,
              appBar: VibeHeader(
                title: AppLocalizations.tr('profile'),
                showBackButton: false,
                actions: [
                  VibeHeaderButton(
                    icon: Icons.notifications_none_rounded,
                    isDark: isDark,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  VibeHeaderButton(
                    icon: Icons.settings_outlined,
                    isDark: isDark,
                    onTap: () => context.router.push(const SettingsRoute()),
                  ),
                ],
              ),
              body: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        SizedBox(
                          height:
                              MediaQuery.of(context).padding.top +
                              VibeHeader.headerHeight +
                              16,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment
                                .center, // Center profile info
                            children: [
                              const SizedBox(height: 12),
                              Center(
                                child: FadeTransition(
                                  opacity: _headerFade,
                                  child: _buildProfileHeader(
                                    isDark,
                                    profileData,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              SlideTransition(
                                position: _statsSlide,
                                child: FadeTransition(
                                  opacity: _headerFade,
                                  child: _buildStatsRow(isDark, profileData),
                                ),
                              ),
                              const SizedBox(height: 24),
                              FadeTransition(
                                opacity: _sectionsFade,
                                child: _buildInterestsSection(
                                  isDark,
                                  profileData,
                                ),
                              ),
                              const SizedBox(height: 24),
                              FadeTransition(
                                opacity: _sectionsFade,
                                child: _buildBadgesSection(isDark, profileData),
                              ),
                              const SizedBox(height: 24),
                              FadeTransition(
                                opacity: _sectionsFade,
                                child: _buildTrustPassportBanner(isDark, profileData.reputationScore),
                              ),
                              const SizedBox(height: 24),
                              FadeTransition(
                                opacity: _sectionsFade,
                                child: _buildActivitySection(isDark),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Profile header ─────────────────────────────────
  Widget _buildProfileHeader(bool isDark, ProfileData profile) {
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : const Color(0xFF1C2C58);

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
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorderLight
                      : AppColors.borderLight,
                  width: 1.5,
                ),
                color: isDark ? AppColors.darkBgTertiary : Colors.white,
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
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          profile.name,
          textAlign: TextAlign.center,
          style: AppTextStyles.headingLarge.copyWith(
            fontSize: 24,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            profile.bio.isNotEmpty
                ? profile.bio
                : 'No bio yet. Tap edit to add one! ✨',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Reputation pill – premium gold
        _ReputationBadge(score: profile.reputationScore),
      ],
    );
  }

  // ─── Stats row ──────────────────────────────────────
  Widget _buildStatsRow(bool isDark, ProfileData profile) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.borderLight.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _StatChip(
                value: '${profile.hostedCount}',
                label: 'Hosted',
                isDark: isDark,
                icon: Icons.auto_awesome_rounded,
                color: const Color(0xFF3B82F6),
              ),
            ),
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(vertical: 8),
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
            ),
            Expanded(
              child: _StatChip(
                value: '${profile.attendingCount}',
                label: 'Attending',
                isDark: isDark,
                icon: Icons.people_alt_rounded,
                color: const Color(0xFF10B981),
              ),
            ),
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(vertical: 8),
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
            ),
            Expanded(
              child: _StatChip(
                value: '${profile.pastCount}',
                label: 'Past',
                isDark: isDark,
                icon: Icons.history_rounded,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Interests section ──────────────────────────────
  Widget _buildInterestsSection(bool isDark, ProfileData profile) {
    final selected = profile.interests
        .where((i) => i['selected'] == true)
        .toList();

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : const Color(0xFF1C2C58);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.tr('interests'),
              style: AppTextStyles.headingSmall.copyWith(
                color: textPrimary,
                fontSize: 18,
              ),
            ),
            if (selected.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
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
        const SizedBox(height: 16),
        if (selected.isEmpty)
          const VibeEmptyState(
            title: 'No interests yet',
            message: 'Add interests so matches and invites fit you better.',
            icon: Icons.interests_rounded,
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: selected.map((interest) {
              final name = interest['name'] as String;
              final iconName = interest['icon'] as String? ?? 'local_activity';

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBgTertiary : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorderLight
                        : AppColors.borderLight.withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getIcon(iconName),
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // ─── Badges section ─────────────────────────────────
  Widget _buildBadgesSection(bool isDark, ProfileData profile) {
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : const Color(0xFF1C2C58);

    final List<_BadgeData> badges = profile.badges.map((b) {
      return _BadgeData(
        icon: _getBadgeIcon(b['icon'] ?? ''),
        name: b['name'] ?? 'Unknown Badge',
        gradient: _getBadgeGradient(b['color'] ?? 'blue'),
        isUnlocked: b['isUnlocked'] ?? true,
        desc: b['description'] ?? '',
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.tr('badges_gallery'),
              style: AppTextStyles.headingSmall.copyWith(
                color: textPrimary,
                fontSize: 18,
              ),
            ),
            if (badges.isNotEmpty)
              Text(
                '${badges.where((b) => b.isUnlocked).length} unlocked',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (badges.isEmpty)
          const VibeEmptyState(
            title: 'No badges yet',
            message: 'Join and host events to unlock profile badges.',
            icon: Icons.military_tech_rounded,
          )
        else
          SizedBox(
            height: 155,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 2),
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
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : const Color(0xFF1C2C58);
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
                  style: AppTextStyles.headingSmall.copyWith(
                    color: textPrimary,
                    fontSize: 18,
                  ),
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
                      horizontal: 14,
                      vertical: 6,
                    ),
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
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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

  // ─── Trust Passport Banner ──────────────────────────
  Widget _buildTrustPassportBanner(bool isDark, int score) {
    final levelData = ReputationService.getLevel(score);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const TrustDashboardPage(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              levelData.gradientColors.first.withValues(alpha: 0.12),
              levelData.gradientColors.last.withValues(alpha: 0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: levelData.color.withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: levelData.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: levelData.color.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🛡️', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hộ chiếu uy tín',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      color: isDark ? Colors.white : const Color(0xFF1C2C58),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        levelData.emoji,
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        levelData.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: levelData.color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: levelData.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$score điểm',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: levelData.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: levelData.color,
            ),
          ],
        ),
      ),
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
            child: const Icon(
              Icons.push_pin_rounded,
              color: AppColors.primary,
              size: 20,
            ),
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
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              event.photoUrls.isNotEmpty
                  ? event.photoUrls.first
                  : 'https://api-prod-minimal-v700.pages.dev/assets/images/cover/cover-${(event.id.hashCode % 20) + 1}.webp',
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
            // Premium Pinned Badge
            Positioned(
              top: 12,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E40AF).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.push_pin_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'FEATURED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
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
                      const Icon(
                        Icons.people_rounded,
                        color: Colors.white70,
                        size: 13,
                      ),
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
                      const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white70,
                        size: 13,
                      ),
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
                : 'https://api-prod-minimal-v700.pages.dev/assets/images/cover/cover-${(event.id.hashCode % 20) + 1}.webp',
            fit: BoxFit.cover,
            errorBuilder: (e, s, t) => Container(color: AppColors.bgSecondary),
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

  IconData _getBadgeIcon(String key) {
    switch (key.toLowerCase()) {
      case 'host':
        return Icons.military_tech_rounded;
      case 'time':
        return Icons.bolt_rounded;
      case 'social':
        return Icons.people_alt_rounded;
      case 'explorer':
        return Icons.explore_rounded;
      case 'champion':
        return Icons.emoji_events_rounded;
      case 'streak':
        return Icons.local_fire_department_rounded;
      case 'growth':
        return Icons.auto_graph_rounded;
      default:
        return Icons.military_tech_rounded;
    }
  }

  List<Color> _getBadgeGradient(String color) {
    switch (color.toLowerCase()) {
      case 'blue':
        return const [Color(0xFF4884C9), Color(0xFF306DB9)];
      case 'yellow':
        return const [Color(0xFFF3B541), Color(0xFFFAA320)];
      case 'green':
        return const [Color(0xFF4CB098), Color(0xFF1DA187)];
      case 'purple':
        return const [Color(0xFF6D48BD), Color(0xFF4E2D95)];
      case 'red':
        return const [Color(0xFFC65050), Color(0xFFB02D2D)];
      case 'gray':
        return const [Color(0xFF444444), Color(0xFF222222)];
      case 'cyan':
        return const [Color(0xFF5197E0), Color(0xFF356FDB)];
      default:
        return const [Color(0xFF4884C9), Color(0xFF306DB9)];
    }
  }
}

// ─── Reputation Badge ─────────────────────────────────────────────────────────
class _ReputationBadge extends StatelessWidget {
  const _ReputationBadge({required this.score});
  final int score;

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
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 18,
            ),
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
              Text(
                '$score',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 26,
                  letterSpacing: -0.5,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Interest Pill (Unused, removed for minimal luxury) ───

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
    final primary = data.isUnlocked
        ? data.gradient.first
        : const Color(0xFF5A5A5A);

    return Container(
      width: 116,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: data.isUnlocked
              ? primary.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: data.isUnlocked
                    ? [
                        data.gradient.first.withValues(
                          alpha: isDark ? 0.9 : 0.95,
                        ),
                        data.gradient.last.withValues(
                          alpha: isDark ? 0.7 : 0.8,
                        ),
                      ]
                    : [const Color(0xFF3A3A3A), const Color(0xFF222222)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: data.isUnlocked ? 0.35 : 0.15,
                ),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon circle
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(
                            alpha: data.isUnlocked ? 0.22 : 0.1,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: data.isUnlocked ? 0.45 : 0.2,
                            ),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          data.icon,
                          color: Colors.white.withValues(
                            alpha: data.isUnlocked ? 1.0 : 0.4,
                          ),
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
                            alpha: data.isUnlocked ? 1.0 : 0.5,
                          ),
                          height: 1.15,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (!data.isUnlocked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
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
                              Icon(
                                Icons.lock_rounded,
                                size: 10,
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'LOCKED',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white.withValues(alpha: 0.45),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    required this.icon,
    required this.color,
  });
  final String value;
  final String label;
  final bool isDark;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1C2C58),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textHint,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
