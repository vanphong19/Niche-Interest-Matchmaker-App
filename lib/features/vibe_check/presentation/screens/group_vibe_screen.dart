import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/vibe_app_bar.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/group_vibe_member_card.dart';
import '../widgets/item_tile.dart';
import '../widgets/matched_user_avatar.dart';

@RoutePage()
class GroupVibeScreen extends StatelessWidget {
  const GroupVibeScreen({super.key});

  static const _avatarA =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuD8gt7lFC8M1TpfbfaOZiN8B0fW8sA8E6XQgjythXrcrRTXbEwnZ0xZ1cF8iVEl8r4UTi4Bx48jf9oqKpuiAe-t9STb26MPASfUCGeoiihQ-HsIf7hci8HaYkwBmBIRZofV6vL66UanY2onyMZ_v_MnkROE8hZ_7Z3U9TUfWhcnehNqyR2uIFlzcvhMFYZrbs9jpsrIbdoKbZNmVbeFMDDaXVChp-5tUSnzBjzRCc1Krrf5R_fi82Nhk9VkUTwySkbWtk0cN-R7lfM';
  static const _avatarB =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuD_QtbKUD1BojVDiBQ2OKqyOQRZWkHpgbbq0k6rX5MGfMMo83O_Cpzwsta7cjNSNg0JkFh-yEdxqm5dT2XlVfUODL1o_cCRN4kIyTga05h2SoMU1KYPx-08VLhG8xOuXBgGHPIKSGpka-zdP4WriGgEDQ3FWq4hwwE_4SGyRpjEXXIPge4jSAW-N2OopEpSqrb1v_dubY64Pdvb9hvtT04N3cwqFRnxEa243WtxVVxVcHrbVvRfQnEJ8K9qWCjBHFbvJy8x6XrTDHw';
  static const _avatarC =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBuWoGVgPDqQ_mgQFxhFF8fw94w7zPtlcaUpDW853B4MIZhY6hvLALv2qWXY5SqQK9jDf9aMVayfEi-mvEJxq94LfjzaNAfT4OEllREUNKZ1_h15Vfp6Sx-lXlTNqszlnfyIqdAWKUTnhtJrl6ZggJc5XW6ZGyblka7eiD_WhoyfMEUQNvD6aMMSnYCRDF5d1BDTfGfbLBB5VebaFdckjx8fe1l6-Kk20YrUQICpO9NboKIBOP9-GjeZE4f6VxmK-uPNWFFCJT07Uk';
  static const _avatarD =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuA0uqZJmAP9lfYLkb9bWqDQBvpC7xdEDKtEeK82BBjOLSsEkddoA9ihOcQHKW06H_2WXTlHVLrL9JsGKTvfRH--A5TflE_or3ZFuDG68_SRQcU6_JSZD0eMZxPR9hXXO2uSRqKIBN-qS4hovjjFwE7e0rGf1W4lePaCjoC4Wh5_nN1c1HER3CJXNHX8LybIsBMqekS7Nlwnho6WJZgrulIGJAolNQC-wV_aTT6bUnlBCE9wl0a-vezAQoRqbvSyPr2rMrYUQHmsr_g';
  static const _avatarE =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCOlH0bYqCjfT1NFTbPxXax7wvT8CEbKGcY6QnwzkyDRMcGfFEJgQSwfojiw-PjhFfOpUbJh1IpvAWG8Y0l9OM7g_7heURvvwJwI2QAQGMnWmd20NCav3Qa-t9j3DhynX438AVPxqgDc_X3SIQAQNbLQx2097V4eJ5GOTiqs76BRZi2WkcsIzRTjO_HjuuLTn09U99S9iIqYgnyiXuVYcLt48qqgl4yG4y6mmWoM-5v2wgBZ9Go8CBSOOaEn6YPOUFNHfOf1lHRaN4';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: VibeAppBar(
        title: 'Vibe Match',
        showBack: false,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: MatchedUserAvatar(
            imageUrl: _avatarA,
            size: 36,
            borderWidth: 2,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveLayout(
          small: (context, info) => _GroupVibeBody(info: info),
          medium: (context, info) => _GroupVibeBody(info: info),
          large: (context, info) => _GroupVibeBody(info: info),
        ),
      ),
    );
  }
}

class _GroupVibeBody extends StatelessWidget {
  const _GroupVibeBody({required this.info});

  final ResponsiveInfo info;

  @override
  Widget build(BuildContext context) {
    final horizontal = (info.width * 0.04).clamp(12.0, 28.0);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            AppSpacing.lg,
            horizontal,
            120,
          ),
          sliver: SliverList.list(
            children: const [
              _GroupHeader(),
              SizedBox(height: AppSpacing.lg),
              _ScoreHero(),
              SizedBox(height: AppSpacing.xl),
              _SocialStack(),
              SizedBox(height: AppSpacing.xl),
              _InsightsSection(),
            ],
          ),
        ),
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Group Analysis',
          style: AppTextStyles.captionMedium.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Weekend Hike Crew',
          style: AppTextStyles.displayMedium.copyWith(
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        const Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ItemTile(label: '#Active', compact: true),
            ItemTile(label: '#Nature', compact: true),
            ItemTile(label: '#Social', compact: true),
          ],
        ),
      ],
    );
  }
}

class _ScoreHero extends StatelessWidget {
  const _ScoreHero();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bgSecondary,
              boxShadow: AppSpacing.shadowLarge,
            ),
            child: Center(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '92',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w900,
                        fontSize: 44,
                      ),
                    ),
                    TextSpan(
                      text: '%',
                      style: AppTextStyles.headingSmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Exceptional Vibe',
            style: AppTextStyles.headingMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'This group has incredibly high energy alignment. Perfect for long, active outings.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SocialStack extends StatelessWidget {
  const _SocialStack();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: const [
          Positioned(
            top: 82,
            child: MatchedUserAvatar(
              imageUrl: GroupVibeScreen._avatarA,
              size: 82,
              badgeText: '98%',
              badgeColor: AppColors.secondary,
            ),
          ),
          Positioned(
            top: 12,
            left: 36,
            child: MatchedUserAvatar(
              imageUrl: GroupVibeScreen._avatarB,
              size: 66,
              badgeText: '94%',
              badgeColor: AppColors.secondary,
            ),
          ),
          Positioned(
            bottom: 14,
            right: 38,
            child: MatchedUserAvatar(
              imageUrl: GroupVibeScreen._avatarC,
              size: 66,
              badgeText: '91%',
              badgeColor: AppColors.secondary,
            ),
          ),
          Positioned(
            top: 38,
            right: 12,
            child: MatchedUserAvatar(
              imageUrl: GroupVibeScreen._avatarD,
              size: 58,
              badgeText: '78%',
              badgeColor: AppColors.warning,
            ),
          ),
          Positioned(
            bottom: 34,
            left: 12,
            child: MatchedUserAvatar(
              imageUrl: GroupVibeScreen._avatarE,
              size: 58,
              badgeText: '88%',
              badgeColor: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightsSection extends StatelessWidget {
  const _InsightsSection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 640;

        final cards = [
          const GroupVibeMemberCard(
            header: 'Strongest Match',
            title: 'Sarah J.',
            subtitle: '98% Match',
            icon: Icons.favorite,
            iconColor: AppColors.secondary,
            imageUrl: GroupVibeScreen._avatarA,
          ),
          const GroupVibeMemberCard(
            header: 'Vibe Check',
            title: 'Mike T.',
            subtitle: 'Low Pace Match',
            icon: Icons.info,
            iconColor: AppColors.warning,
            imageUrl: GroupVibeScreen._avatarD,
          ),
        ];

        return Column(
          children: [
            if (!isWide) ...[
              cards[0],
              const SizedBox(height: AppSpacing.md),
              cards[1],
            ] else
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: cards[1]),
                ],
              ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Group Personality',
                    style: AppTextStyles.headingSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'The majority of this group prefers an energetic, fast-paced environment. Consider adjusting the route to accommodate Mike\'s preferred casual pace.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Suggest Route Adjustment',
                    filled: false,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
