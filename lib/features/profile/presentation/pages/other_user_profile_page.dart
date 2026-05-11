// lib/features/profile/presentation/pages/other_user_profile_page.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../router/app_router.gr.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../core/widgets/vibe_button.dart';
import '../../../../core/widgets/snackbar_service.dart';
import '../../../../core/utils/profile_state.dart';
import '../../data/services/user_api_service.dart';
import '../../../../injection/injection_container.dart';
import '../../../../core/widgets/vibe_header.dart';

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
  final bool _hasSharedExperience = false;

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
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await sl<UserApiService>().getOtherProfile(widget.userId);
      if (mounted) {
        setState(() {
          _otherProfile = profile;
          _isLoading = false;
        });
        _animController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        VibeSnackBar.error(context, 'Failed to load profile');
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBgPrimary : const Color(0xFFF5F7FF);
    final cardColor = isDark ? AppColors.darkCardBackground : Colors.white;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : const Color(0xFF1C2C58);

    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.localeNotifier,
      builder: (context, _, _) {
        if (_isLoading) {
          return Scaffold(
            backgroundColor: bgColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (_otherProfile == null) {
          return Scaffold(
            backgroundColor: bgColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('User not found'),
                  const SizedBox(height: 16),
                  VibeButton(
                    label: 'Go Back',
                    onPressed: () => context.router.maybePop(),
                    width: 120,
                  ),
                ],
              ),
            ),
          );
        }

        final profile = _otherProfile!;

        return Scaffold(
          backgroundColor: bgColor,
          extendBodyBehindAppBar: true,
          appBar: VibeHeader(
            title: profile.name,
            showBackButton: true,
            actions: [
              _HeaderIcon(
                icon: Icons.more_horiz_rounded,
                isDark: isDark,
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top + 52 + 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
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
                              child: _buildStats(cardColor, isDark, profile),
                            ),
                          ),
                          if (profile.username != ProfileState.notifier.value.username) ...[
                            const SizedBox(height: 20),
                            // Interaction Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: VibeButton(
                                    label: AppLocalizations.tr('message'),
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      VibeSnackBar.info(
                                        context,
                                        'Opening chat...',
                                      );
                                    },
                                    type: VibeButtonType.primary,
                                    prefixIcon: Icons.chat_bubble_outline_rounded,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: VibeButton(
                                    label: AppLocalizations.tr('rate'),
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      if (_hasSharedExperience) {
                                        VibeSnackBar.success(
                                          context,
                                          'Thanks! Your rating was sent.',
                                        );
                                      } else {
                                        VibeSnackBar.info(
                                          context,
                                          'Rating opens after joining at least one event together.',
                                        );
                                      }
                                    },
                                    type: VibeButtonType.outlined,
                                    prefixIcon: Icons.star_rate_rounded,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: VibeButton(
                                label: 'Invite to private event',
                                onPressed: () => VibeSnackBar.info(
                                  context,
                                  'Invite sent to private event.',
                                ),
                                type: VibeButtonType.secondary,
                                prefixIcon: Icons.group_add_rounded,
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          // Interests
                          FadeTransition(
                            opacity: _sectionsFade,
                            child: _buildInterestsSection(
                              isDark,
                              textPrimary,
                              profile,
                            ),
                          ),
                          const SizedBox(height: 28),
                          // Badges Gallery
                          FadeTransition(
                            opacity: _sectionsFade,
                            child: _buildBadgesSection(isDark, textPrimary, profile),
                          ),
                          const SizedBox(height: 28),
                          // Activity History
                          FadeTransition(
                            opacity: _sectionsFade,
                            child: _buildActivitySection(isDark, textPrimary),
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
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 3),
                
              ),
              child: VibeAvatar(
                imageUrl: profile.avatarUrl,
                name: profile.name,
                size: 106,
                showBorder: false,
              ),
            ),
            Positioned(
              right: -2,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          profile.name,
          style: AppTextStyles.headingLarge.copyWith(
            fontSize: 32,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '@${profile.username}',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            profile.bio,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        // Premium Reputation Badge - Rich Golden Style
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFECCE8E), Color(0xFFD29842), Color(0xFFECCB76)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 1,
            ),
            
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -10,
                right: -10,
                child: Icon(
                  Icons.star_rounded,
                  size: 40,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.hotel_class_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    AppLocalizations.tr('reputation_score'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${profile.reputationScore}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 24,
                      shadows: [
                        Shadow(
                          color: Color(0x40000000),
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
        ),
      ],
    );
  }

  Widget _buildStats(Color cardColor, bool isDark, ProfileData profile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            value: '${profile.createdCount}',
            label: 'Hosting',
            isDark: isDark,
            icon: Icons.auto_awesome_rounded,
          ),
          _StatItem(
            value: '${profile.joinedCount}',
            label: 'Joined',
            isDark: isDark,
            icon: Icons.people_alt_rounded,
          ),
          _StatItem(
            value: '${profile.friendsCount}',
            label: 'Friends',
            isDark: isDark,
            icon: Icons.favorite_rounded,
          ),
        ],
      ),
    );
  }

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
            final name = interest['name'] as String;
            final icon = getIcon(interest['icon'] as String);
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
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
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

  Widget _buildBadgesSection(bool isDark, Color textPrimary, ProfileData profile) {
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

  Widget _buildActivitySection(bool isDark, Color textPrimary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.tr('activity_history'),
              style: AppTextStyles.headingSmall.copyWith(color: textPrimary),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Public highlights',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          onTap: () =>
              context.router.push(EventDetailRoute(eventId: 'evt-005')),
          child: _buildHeroActivity(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    context.router.push(EventDetailRoute(eventId: 'evt-002')),
                child: _buildMiniActivity(
                  'Artisan Coffee Crawl',
                  'Dec 12, 2024',
                  'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=500&q=80',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    context.router.push(EventDetailRoute(eventId: 'evt-001')),
                child: _buildMiniActivity(
                  'Sunrise HIIT Squad',
                  'Dec 08, 2024',
                  'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=500&q=80',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroActivity() {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1551632811-561732d1e306?auto=format&fit=crop&w=900&q=80',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black87],
          ),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'LAST SUNDAY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Hudson Valley Peak Trail',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
            Text(
              '12 Participants',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniActivity(String title, String date, String image) {
    return Container(
      height: 108,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        image: DecorationImage(image: NetworkImage(image), fit: BoxFit.cover),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black87],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            Text(
              date,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
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
  });
  final String value;
  final String label;
  final bool isDark;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF1C2C58),
            letterSpacing: -0.5,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textHint,
            letterSpacing: 0.2,
          ),
        ),
      ],
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

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.icon,
    required this.isDark,
  });
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : AppColors.borderLight,
        ),
      ),
      child: Icon(icon,
          size: 20, color: isDark ? Colors.white : AppColors.primary),
    );
  }
}
