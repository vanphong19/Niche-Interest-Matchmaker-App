// lib/features/profile/presentation/pages/other_user_profile_page.dart
import 'dart:async';
import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../router/app_router.gr.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../core/widgets/vibe_empty_state.dart';
import '../../../../core/widgets/snackbar_service.dart';
import '../../../../core/utils/profile_state.dart';
import '../../../../core/services/signalr_service.dart';
import '../../data/services/user_api_service.dart';
import '../../../../injection/injection_container.dart';
import '../../../../core/widgets/vibe_header.dart';
import '../../../event/data/services/event_api_service.dart';
import '../../../event/domain/entities/event.dart';

@RoutePage()
class OtherUserProfilePage extends StatefulWidget {
  final String userId;
  const OtherUserProfilePage({
    super.key,
    @PathParam('id') required this.userId,
  });

  @override
  State<OtherUserProfilePage> createState() => _OtherUserProfilePageState();
}

class _OtherUserProfilePageState extends State<OtherUserProfilePage>
    with SingleTickerProviderStateMixin {
  ProfileData? _otherProfile;
  bool _isLoading = true;
  bool _historyLoading = true;
  bool _friendActionLoading = false;
  List<Event> _profileEvents = const [];
  StreamSubscription<Map<String, dynamic>>? _realtimeSubscription;

  late AnimationController _animController;
  late Animation<double> _headerFade;
  late Animation<Offset> _statsSlide;
  late Animation<double> _sectionsFade;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _statsSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
          ),
        );
    _sectionsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _fetchProfile();
    _realtimeSubscription = sl<SignalRService>().dataChangeStream.listen((_) {
      _fetchProfile(showLoading: false);
    });
  }

  Future<void> _fetchProfile({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _isLoading = true);
    try {
      final profile = await sl<UserApiService>().getOtherProfile(widget.userId);
      final events = await _loadProfileEvents(profile);
      if (mounted) {
        setState(() {
          _otherProfile = profile;
          _profileEvents = events;
          _isLoading = false;
          _historyLoading = false;
        });
        _animController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _historyLoading = false;
        VibeSnackBar.error(context, 'Failed to load profile');
      }
    }
  }

  Future<List<Event>> _loadProfileEvents(ProfileData profile) async {
    final pinnedIds = profile.pinnedMatchIds
        .where((id) => id.trim().isNotEmpty)
        .toList();
    if (pinnedIds.isEmpty) return const [];

    try {
      final api = sl<EventApiService>();
      final events = <Event>[];
      for (final id in pinnedIds) {
        try {
          events.add(await api.getEventDetail(id));
        } catch (_) {}
      }
      events.sort((a, b) => b.startDateTime.compareTo(a.startDateTime));
      return events;
    } catch (_) {
      return const [];
    }
  }

  Future<void> _requestFriend() async {
    final profile = _otherProfile;
    if (profile == null) return;
    setState(() => _friendActionLoading = true);
    try {
      await sl<UserApiService>().requestFriend(profile.id);
      if (!mounted) return;
      setState(() {
        _otherProfile = profile.copyWith(friendshipStatus: 'Requested');
        _friendActionLoading = false;
      });
      sl<SignalRService>().emitLocalChange('friendship', {
        'userId': profile.id,
      });
      VibeSnackBar.success(context, 'Friend request sent');
    } catch (e) {
      if (mounted) {
        setState(() => _friendActionLoading = false);
        VibeFeedback.apiError(context, e);
      }
    }
  }

  Future<void> _removeFriendship() async {
    final profile = _otherProfile;
    if (profile == null) return;

    final status = profile.friendshipStatus.toLowerCase();
    final wasFriend = status == 'accepted' || status == 'friend';
    setState(() => _friendActionLoading = true);
    try {
      await sl<UserApiService>().unfriend(profile.id);
      if (!mounted) return;
      setState(() {
        _otherProfile = profile.copyWith(
          friendshipStatus: 'None',
          friendsCount: wasFriend && profile.friendsCount > 0
              ? profile.friendsCount - 1
              : profile.friendsCount,
        );
        _friendActionLoading = false;
      });
      sl<SignalRService>().emitLocalChange('friendship', {
        'userId': profile.id,
      });
      VibeSnackBar.success(
        context,
        wasFriend ? 'Friend removed' : 'Friend request cancelled',
      );
    } catch (e) {
      if (mounted) {
        setState(() => _friendActionLoading = false);
        VibeFeedback.apiError(context, e);
      }
    }
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBgPrimary : const Color(0xFFF5F7FF);
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : const Color(0xFF1C2C58);

    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.localeNotifier,
      builder: (context, _, _) {
        if (_isLoading) {
          return _OtherProfileSkeleton(isDark: isDark);
        }

        if (_otherProfile == null) {
          return Scaffold(
            backgroundColor: bgColor,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: VibeEmptyState(
                  title: 'User not found',
                  message:
                      'This profile may have been removed or is no longer available.',
                  icon: Icons.person_off_outlined,
                  actionLabel: 'Go Back',
                  onAction: () => context.router.maybePop(),
                ),
              ),
            ),
          );
        }

        final profile = _otherProfile!;

        return Scaffold(
          backgroundColor: bgColor,
          extendBodyBehindAppBar: true,
          appBar: VibeHeader(title: profile.name, showBackButton: true),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
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
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          // Avatar & Info
                          FadeTransition(
                            opacity: _headerFade,
                            child: _buildProfileHeader(
                              isDark,
                              textPrimary,
                              profile,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Stats
                          SlideTransition(
                            position: _statsSlide,
                            child: FadeTransition(
                              opacity: _headerFade,
                              child: _buildStats(isDark, profile),
                            ),
                          ),
                          if (profile.username !=
                              ProfileState.notifier.value.username) ...[
                            const SizedBox(height: 20),
                            _buildProfileActions(isDark, profile),
                          ],
                          const SizedBox(height: 28),
                          // Interests
                          FadeTransition(
                            opacity: _sectionsFade,
                            child: _buildProfileInterestsSection(
                              isDark,
                              profile,
                            ),
                          ),
                          const SizedBox(height: 28),
                          // Badges Gallery
                          FadeTransition(
                            opacity: _sectionsFade,
                            child: _buildProfileBadgesSection(isDark, profile),
                          ),
                          const SizedBox(height: 28),
                          // Activity History
                          FadeTransition(
                            opacity: _sectionsFade,
                            child: _buildProfileActivitySection(
                              isDark,
                              profile,
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
        );
      },
    );
  }

  Widget _buildProfileActions(bool isDark, ProfileData profile) {
    final status = profile.friendshipStatus.toLowerCase();
    final isPending = status == 'requested' || status == 'pending';
    final isFriend = status == 'accepted' || status == 'friend';

    return Row(
      children: [
        Expanded(
          child: _ProfileActionButton(
            label: AppLocalizations.tr('message'),
            icon: Icons.message_rounded,
            isPrimary: false,
            isDark: isDark,
            onTap: () {
              HapticFeedback.selectionClick();
              VibeSnackBar.info(context, 'Opening chat...');
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ProfileActionButton(
            label: isFriend
                ? 'Friends'
                : isPending
                ? 'Cancel'
                : 'Add friend',
            icon: isFriend
                ? Icons.check_rounded
                : isPending
                ? Icons.close_rounded
                : Icons.person_add_rounded,
            isPrimary: !isFriend && !isPending,
            isDestructive: false,
            isDark: isDark,
            isLoading: _friendActionLoading,
            onTap: isFriend || isPending ? _removeFriendship : _requestFriend,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(
    bool isDark,
    Color textPrimary,
    ProfileData profile,
  ) {
    return Column(
      children: [
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
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 14,
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
            profile.bio.isNotEmpty ? profile.bio : 'No bio yet. ✨',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _ReputationBadge(score: profile.reputationScore),
      ],
    );
  }

  Widget _buildStats(bool isDark, ProfileData profile) {
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
              child: _StatItem(
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
              child: _StatItem(
                value: '${profile.attendingCount}',
                label: 'Joined',
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
              child: _StatItem(
                value: '${profile.friendsCount}',
                label: 'Friends',
                isDark: isDark,
                icon: Icons.favorite_rounded,
                color: const Color(0xFFF43F5E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInterestsSection(bool isDark, ProfileData profile) {
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
              final name = (interest['name'] ?? '').toString();
              final iconName = (interest['icon'] ?? 'local_activity')
                  .toString();
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

  Widget _buildProfileBadgesSection(bool isDark, ProfileData profile) {
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : const Color(0xFF1C2C58);
    final badges = profile.badges.map((badge) {
      return _BadgeData(
        icon: _getBadgeIcon((badge['icon'] ?? '').toString()),
        name: (badge['name'] ?? 'Unknown Badge').toString(),
        gradient: _getBadgeGradient((badge['color'] ?? 'blue').toString()),
        isUnlocked: badge['isUnlocked'] ?? true,
        desc: (badge['description'] ?? '').toString(),
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
                '${badges.where((badge) => badge.isUnlocked).length} unlocked',
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
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _BadgeCard(data: badges[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileActivitySection(bool isDark, ProfileData profile) {
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : const Color(0xFF1C2C58);
    final pinned = _profileEvents;
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
            if (pinned.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Public highlights',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
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
              color: isDark ? const Color(0xFF1A2232) : AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(16),
            ),
          )
        else if (featured == null)
          _buildNoActivityPrompt(isDark)
        else ...[
          GestureDetector(
            onTap: () =>
                context.router.push(EventDetailRoute(eventId: featured.id)),
            child: _buildFeaturedActivityCard(featured, isDark),
          ),
          if (rest.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 116,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: rest.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final event = rest[index];
                  return GestureDetector(
                    onTap: () => context.router.push(
                      EventDetailRoute(eventId: event.id),
                    ),
                    child: SizedBox(
                      width: 200,
                      child: _buildMiniActivityCard(event),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildNoActivityPrompt(bool isDark) {
    return const VibeEmptyState(
      title: 'No public activity yet',
      message: 'Pinned public events from this profile will appear here.',
      icon: Icons.push_pin_rounded,
      compact: true,
    );
  }

  Widget _buildFeaturedActivityCard(Event event, bool isDark) {
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
              errorBuilder: (context, error, stackTrace) =>
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
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.push_pin_rounded, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
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

  Widget _buildMiniActivityCard(Event event) {
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
            errorBuilder: (context, error, stackTrace) =>
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

  // ignore: unused_element
  Widget _buildInterestsSection(
    bool isDark,
    Color textPrimary,
    ProfileData profile,
  ) {
    final selectedInterests = profile.interests
        .where((i) => i['selected'] == true)
        .toList();
    if (selectedInterests.isEmpty) return const SizedBox();

    IconData getIcon(String name) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.tr('interests'),
          style: AppTextStyles.headingSmall.copyWith(color: textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: selectedInterests.map((interest) {
            final name = (interest['name'] ?? '').toString();
            final icon = getIcon(
              (interest['icon'] ?? 'local_activity').toString(),
            );
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF262C3A)
                    : const Color(0xFFF3F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? Colors.white10 : AppColors.borderLight,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.secondary,
                      fontSize: 13,
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

  // ignore: unused_element
  Widget _buildBadgesSection(
    bool isDark,
    Color textPrimary,
    ProfileData profile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.tr('badges_gallery'),
              style: AppTextStyles.headingSmall.copyWith(color: textPrimary),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${profile.badgesCount} ${AppLocalizations.tr('unlocked')}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 155,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: const BouncingScrollPhysics(),
            children: const [
              _PremiumBadgeCard(
                icon: Icons.military_tech_rounded,
                name: 'Top Host',
                gradient: [Color(0xFF5D7B9A), Color(0xFF384B66)],
                isUnlocked: true,
              ),
              _PremiumBadgeCard(
                icon: Icons.bolt_rounded,
                name: 'Punctual King',
                gradient: [Color(0xFFC0A062), Color(0xFF907137)],
                isUnlocked: true,
              ),
              _PremiumBadgeCard(
                icon: Icons.people_alt_rounded,
                name: 'Social Butterfly',
                gradient: [Color(0xFF6F9992), Color(0xFF42655F)],
                isUnlocked: true,
              ),
              _PremiumBadgeCard(
                icon: Icons.explore_rounded,
                name: 'Explorer',
                gradient: [Color(0xFF8675A9), Color(0xFF5B4A78)],
                isUnlocked: true,
              ),
              _PremiumBadgeCard(
                icon: Icons.emoji_events_rounded,
                name: 'Champion',
                gradient: [Color(0xFFB1806F), Color(0xFF8B5A4B)],
                isUnlocked: true,
              ),
              _PremiumBadgeCard(
                icon: Icons.local_fire_department_rounded,
                name: 'Streak Master',
                gradient: [Color(0xFFE2B7B7), Color(0xFFC99898)],
                isUnlocked: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildActivitySection(bool isDark, Color textPrimary) {
    return const VibeEmptyState(
      title: 'No public activity yet',
      message: 'Pinned public events from this profile will appear here.',
      icon: Icons.push_pin_rounded,
      compact: true,
    );
  }
}

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
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                      ),
                      child: Text(
                        'LOCKED',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: Colors.white.withValues(alpha: 0.45),
                          letterSpacing: 0.8,
                        ),
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

class _OtherProfileSkeleton extends StatelessWidget {
  const _OtherProfileSkeleton({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.darkBgPrimary : const Color(0xFFF5F7FF);
    final blockColor = isDark ? AppColors.darkBgSecondary : Colors.white;
    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: VibeHeader(title: 'Profile', showBackButton: true),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + VibeHeader.headerHeight + 28,
          20,
          0,
        ),
        child: Column(
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: blockColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: 180,
              height: 28,
              decoration: BoxDecoration(
                color: blockColor,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: 120,
              height: 16,
              decoration: BoxDecoration(
                color: blockColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 96,
              decoration: BoxDecoration(
                color: blockColor,
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: blockColor,
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
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

class _ProfileActionButton extends StatefulWidget {
  const _ProfileActionButton({
    required this.label,
    required this.icon,
    required this.isDark,
    required this.onTap,
    this.isPrimary = false,
    this.isDestructive = false,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final bool isDark;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool isDestructive;
  final bool isLoading;

  @override
  State<_ProfileActionButton> createState() => _ProfileActionButtonState();
}

class _ProfileActionButtonState extends State<_ProfileActionButton> {
  bool _pressed = false;

  bool get _enabled => widget.onTap != null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isPrimary
        ? AppColors.secondary
        : widget.isDestructive
        ? AppColors.error.withValues(alpha: widget.isDark ? 0.22 : 0.1)
        : widget.label == 'Friends'
        ? AppColors.success.withValues(alpha: widget.isDark ? 0.18 : 0.11)
        : widget.isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.86);
    final fgColor = widget.isPrimary
        ? Colors.white
        : widget.isDestructive
        ? AppColors.error
        : widget.label == 'Friends'
        ? AppColors.success
        : widget.isDark
        ? AppColors.darkTextPrimary
        : AppColors.secondary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
      onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
      onTap: _enabled
          ? () {
              HapticFeedback.selectionClick();
              widget.onTap?.call();
            }
          : null,
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: widget.isPrimary
                  ? Colors.white.withValues(alpha: 0.12)
                  : widget.isDark
                  ? Colors.white.withValues(alpha: 0.09)
                  : Colors.white,
            ),
            boxShadow: [
              if (!widget.isDark)
                BoxShadow(
                  color: widget.isPrimary
                      ? AppColors.secondary.withValues(alpha: 0.16)
                      : const Color(0xFF1C2C58).withValues(alpha: 0.08),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: fgColor,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon, size: 18, color: fgColor),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: fgColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
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
}

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

class _PremiumBadgeCard extends StatelessWidget {
  const _PremiumBadgeCard({
    required this.icon,
    required this.name,
    required this.gradient,
    this.isUnlocked = true,
  });
  final IconData icon;
  final String name;
  final List<Color> gradient;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isUnlocked
              ? gradient
              : [Colors.grey.shade300, Colors.grey.shade400],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Background glow icon
          Positioned(
            right: -12,
            top: -12,
            child: Icon(
              icon,
              size: 72,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon circle with glass effect
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                if (!isUnlocked) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          color: Colors.white70,
                          size: 10,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Locked',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
