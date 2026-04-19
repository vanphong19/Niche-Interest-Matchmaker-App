import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/vibe_app_bar.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/item_tile.dart';
import '../widgets/user_activity_card.dart';

@RoutePage()
class UserDetailScreen extends StatelessWidget {
  const UserDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: VibeAppBar(
        title: 'Profile',
        translucent: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'More options',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveLayout(
          small: (context, info) => _UserDetailBody(info: info),
          medium: (context, info) => _UserDetailBody(info: info),
          large: (context, info) => _UserDetailBody(info: info),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary.withValues(alpha: 0.92),
          boxShadow: AppSpacing.shadowLarge,
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Message',
                  icon: Icons.chat_bubble_rounded,
                  filled: false,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: 'Invite to Event',
                  icon: Icons.event_rounded,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserDetailBody extends StatelessWidget {
  const _UserDetailBody({required this.info});

  final ResponsiveInfo info;

  @override
  Widget build(BuildContext context) {
    final horizontal = (info.width * 0.05).clamp(14.0, 30.0);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            AppSpacing.md,
            horizontal,
            140,
          ),
          sliver: SliverList.list(
            children: const [
              _ProfileHero(),
              SizedBox(height: AppSpacing.xl),
              _ProfileMatchSummary(),
              SizedBox(height: AppSpacing.xl),
              _AboutAndInterests(),
              SizedBox(height: AppSpacing.xl),
              _RecentActivity(),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.bgPrimary, width: 4),
                    boxShadow: AppSpacing.shadowLarge,
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuAIzag-KUSATGxVrHn8TMtQ1dr4GtCIEERXCK2LM9yyl--vcxCTSX5uiOl1m3XHwvu5teJ0qXFIicpKKzEwUX2Q-5QCzTnmYTl5vBg4e522CFxM0IDeh-0GzyQBhWbigdxSujUIUws0clUI6vQpskzS4JxFwZJbSexiCeUnFmoj9Jq5Is_j41FQVgaNyOF8fa7I9XgyKUnF_JNlA9S0jvAteYIBOR66xh-aU8E7AJcHclO02Jsz-UZlHJSh53palUeaJpqXflC14ZU',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.bgPrimary,
                    shape: BoxShape.circle,
                    boxShadow: AppSpacing.shadowMedium,
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '92%',
                        style: AppTextStyles.captionMedium.copyWith(
                          color: AppColors.textInverse,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Sarah Jenkins',
          style: AppTextStyles.displayMedium.copyWith(
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Austin, TX • 2 miles away',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileMatchSummary extends StatelessWidget {
  const _ProfileMatchSummary();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth <= 420;

          if (compact) {
            return const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetricBlock(
                  label: 'Vibe Match',
                  primary: 'High',
                  secondary: '92% Compatibility',
                  primaryColor: AppColors.secondary,
                ),
                SizedBox(height: AppSpacing.lg),
                Divider(color: AppColors.borderLight),
                SizedBox(height: AppSpacing.lg),
                _ReputationBlock(),
              ],
            );
          }

          return const Row(
            children: [
              Expanded(
                child: _MetricBlock(
                  label: 'Vibe Match',
                  primary: 'High',
                  secondary: '92% Compatibility',
                  primaryColor: AppColors.secondary,
                ),
              ),
              SizedBox(width: AppSpacing.lg),
              SizedBox(
                height: 50,
                child: VerticalDivider(color: AppColors.borderLight),
              ),
              SizedBox(width: AppSpacing.lg),
              Expanded(child: _ReputationBlock()),
            ],
          );
        },
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
    required this.label,
    required this.primary,
    required this.secondary,
    required this.primaryColor,
  });

  final String label;
  final String primary;
  final String secondary;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Text(
              primary,
              style: AppTextStyles.headingMedium.copyWith(
                color: primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(secondary, style: AppTextStyles.captionLarge),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReputationBlock extends StatelessWidget {
  const _ReputationBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reputation',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            const Icon(Icons.star_rounded, size: 20, color: AppColors.warning),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '4.9',
              style: AppTextStyles.headingMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text('(42 Meetups)', style: AppTextStyles.captionLarge),
          ],
        ),
      ],
    );
  }
}

class _AboutAndInterests extends StatelessWidget {
  const _AboutAndInterests();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About Sarah',
          style: AppTextStyles.headingMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Always down for a spontaneous coffee run or a long hike at the greenbelt. Looking for folks who enjoy trying new food spots and deep conversations over matcha.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'INTERESTS',
          style: AppTextStyles.captionSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: const [
            ItemTile(
              label: 'Hiking',
              compact: true,
              backgroundColor: AppColors.successLight,
              textColor: AppColors.secondary,
            ),
            ItemTile(label: 'Coffee Spots', compact: true),
            ItemTile(label: 'Live Music', compact: true),
            ItemTile(
              label: 'Photography',
              compact: true,
              backgroundColor: AppColors.successLight,
              textColor: AppColors.secondary,
            ),
            ItemTile(label: 'Dogs', compact: true),
          ],
        ),
      ],
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: AppTextStyles.headingMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 720) {
              return const Column(
                children: [
                  UserActivityCard(
                    type: 'HOSTED',
                    title: 'Sunday Morning Hike',
                    timeLabel: 'Last week',
                    icon: Icons.park_rounded,
                    accentColor: AppColors.primary,
                  ),
                  SizedBox(height: AppSpacing.md),
                  UserActivityCard(
                    type: 'ATTENDED',
                    title: 'Downtown Art Walk',
                    timeLabel: '2 weeks ago',
                    icon: Icons.palette_rounded,
                    accentColor: AppColors.warning,
                  ),
                ],
              );
            }

            return const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: UserActivityCard(
                    type: 'HOSTED',
                    title: 'Sunday Morning Hike',
                    timeLabel: 'Last week',
                    icon: Icons.park_rounded,
                    accentColor: AppColors.primary,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: UserActivityCard(
                    type: 'ATTENDED',
                    title: 'Downtown Art Walk',
                    timeLabel: '2 weeks ago',
                    icon: Icons.palette_rounded,
                    accentColor: AppColors.warning,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
