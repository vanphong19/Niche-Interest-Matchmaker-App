import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/utils/responsive_layout.dart';
import 'match_details_screen.dart';
import '../widgets/header_section.dart';
import '../widgets/match_profile_card.dart';

@RoutePage()
class UserMatchListScreen extends StatefulWidget {
  const UserMatchListScreen({super.key});

  @override
  State<UserMatchListScreen> createState() => _UserMatchListScreenState();
}

class _UserMatchListScreenState extends State<UserMatchListScreen> {
  static const List<MatchProfileData> _matches = [
    MatchProfileData(
      name: 'Alex',
      age: 24,
      distanceMiles: 2,
      matchPercent: 98,
      bio:
          'Always down for a spontaneous coffee run or a long hike. Looking for deep convos.',
      imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
      interests: ['Photography', 'Hiking'],
      hasSharedTag: true,
      flag: MatchProfileFlag.reliable,
    ),
    MatchProfileData(
      name: 'Jordan',
      age: 27,
      distanceMiles: 5,
      matchPercent: 85,
      bio:
          'Just moved here! Exploring the local food scene and looking for gym buddies.',
      imageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2',
      interests: ['Foodie', 'Fitness'],
      flag: MatchProfileFlag.newcomer,
    ),
    MatchProfileData(
      name: 'Sam',
      age: 22,
      distanceMiles: 1,
      matchPercent: 60,
      bio:
          'Night owl. You can usually find me at an indie gig or thrifting downtown.',
      imageUrl: 'https://images.unsplash.com/photo-1531427186611-ecfd6d936c79',
      interests: ['Live Music', 'Art'],
      flag: MatchProfileFlag.lateRisk,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final match in _matches) {
        precacheImage(NetworkImage(match.imageUrl), context);
      }
    });
  }

  void _openMatchDetails(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const MatchDetailsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: ResponsiveLayout(
          small: (context, info) => _AdaptiveMatchList(
            info: info,
            matches: _matches,
            onView: () => _openMatchDetails(context),
          ),
          medium: (context, info) => _AdaptiveMatchList(
            info: info,
            matches: _matches,
            onView: () => _openMatchDetails(context),
          ),
          large: (context, info) => _AdaptiveMatchList(
            info: info,
            matches: _matches,
            onView: () => _openMatchDetails(context),
          ),
        ),
      ),
    );
  }
}

class _AdaptiveMatchList extends StatelessWidget {
  const _AdaptiveMatchList({
    required this.info,
    required this.matches,
    required this.onView,
  });

  final ResponsiveInfo info;
  final List<MatchProfileData> matches;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = (info.width * 0.04).clamp(12.0, 36.0);
    final sectionGap = (info.width * 0.05).clamp(16.0, 30.0);
    final titleSize = ResponsiveValue<double>(
      verySmall: 22,
      small: 24,
      medium: 30,
      large: 34,
    ).resolve(info.width);
    final shouldUseList = info.isSmall || (info.isMedium && !info.isLandscape);
    final crossAxisCount = info.width >= 1100 ? 3 : (info.width >= 760 ? 2 : 1);

    if (matches.isEmpty) {
      return Center(
        child: FractionallySizedBox(
          widthFactor: info.isLarge ? 0.55 : 0.88,
          child: Padding(
            padding: EdgeInsets.all(sectionGap),
            child: Text(
              AppLocalizations.tr('no_matches_yet'),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }

    return CustomScrollView(
      cacheExtent: info.isLarge ? 1200 : 900,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            horizontalPadding,
            horizontalPadding,
            sectionGap,
          ),
          sliver: SliverList.list(
            children: [
              HeaderSection(
                title: AppLocalizations.tr('vibe_match_title'),
                onSettingsPressed: () {},
              ),
              Text(
                AppLocalizations.tr('your_top_matches'),
                style: AppTextStyles.displayMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: titleSize,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: (info.width * 0.02).clamp(6.0, 12.0)),
              Text(
                AppLocalizations.tr('top_matches_subtitle'),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: ResponsiveValue<double>(
                    verySmall: 12,
                    small: 12.5,
                    medium: 13.5,
                    large: 14,
                  ).resolve(info.width),
                ),
                maxLines: info.isVerySmall ? 4 : 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            110,
          ),
          sliver: shouldUseList
              ? SliverList.separated(
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final profile = matches[index];
                    return RepaintBoundary(
                      child: KeyedSubtree(
                        key: ValueKey(profile.imageUrl),
                        child: MatchProfileCard(
                          profile: profile,
                          onView: onView,
                          onChat: profile.matchPercent >= 80 ? onView : null,
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      SizedBox(height: (info.width * 0.04).clamp(14.0, 24.0)),
                )
              : SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: (info.width * 0.025).clamp(14.0, 24.0),
                    crossAxisSpacing: (info.width * 0.025).clamp(14.0, 24.0),
                    childAspectRatio: info.isLandscape ? 0.76 : 0.7,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final profile = matches[index];
                    return RepaintBoundary(
                      child: KeyedSubtree(
                        key: ValueKey(profile.imageUrl),
                        child: MatchProfileCard(
                          profile: profile,
                          onView: onView,
                          onChat: profile.matchPercent >= 80 ? onView : null,
                        ),
                      ),
                    );
                  }, childCount: matches.length),
                ),
        ),
      ],
    );
  }
}
