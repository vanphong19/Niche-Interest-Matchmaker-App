import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../core/widgets/vibe_app_bar.dart';
import '../../../../injection/injection_container.dart';
import '../../../../router/app_router.gr.dart';
import '../../domain/entities/group_vibe_check_result.dart';
import '../bloc/group_vibe_check_bloc.dart';
import '../bloc/group_vibe_check_event.dart';
import '../bloc/group_vibe_check_state.dart';

class GroupVibeCheckResultPage extends StatelessWidget {
  const GroupVibeCheckResultPage({
    super.key,
    required this.matchId,
    this.maxMembers,
  });

  final String matchId;
  final int? maxMembers;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<GroupVibeCheckBloc>()
            ..add(PerformGroupVibeCheck(matchId, maxMembers: maxMembers)),
      child: const _GroupVibeCheckResultBody(),
    );
  }
}

class _GroupVibeCheckResultBody extends StatelessWidget {
  const _GroupVibeCheckResultBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: VibeAppBar(
        title: AppLocalizations.tr('group_vibe_check_title'),
        showBack: true,
        translucent: true,
      ),
      body: SafeArea(
        child: BlocBuilder<GroupVibeCheckBloc, GroupVibeCheckState>(
          builder: (context, state) {
            if (state is GroupVibeCheckLoading) {
              return const _LoadingView();
            }
            if (state is GroupVibeCheckError) {
              return _ErrorView(message: state.message);
            }
            if (state is GroupVibeCheckSuccess) {
              return _SuccessView(result: state.result);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: AppSpacing.xl),
            Text(
              AppLocalizations.tr('group_vibe_loading_title'),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMediumSemiBold,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppLocalizations.tr('group_vibe_loading_desc'),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  bool get _needsProfileUpdate {
    final lower = message.toLowerCase();
    return lower.contains('profile') ||
        lower.contains('ho so') ||
        lower.contains('hồ sơ') ||
        lower.contains('bio') ||
        lower.contains('interests');
  }

  @override
  Widget build(BuildContext context) {
    final text = _fallbackMessage(message);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.groups_2_outlined,
                color: AppColors.warning,
                size: 36,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppLocalizations.tr('group_vibe_error_title'),
              textAlign: TextAlign.center,
              style: AppTextStyles.headingSmall.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_needsProfileUpdate) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () =>
                      context.router.push(const EditProfileRoute()),
                  icon: const Icon(Icons.edit_rounded),
                  label: Text(AppLocalizations.tr('update_profile')),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(AppLocalizations.tr('back_to_event')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fallbackMessage(String value) {
    if (value.trim().isEmpty) {
      return AppLocalizations.tr('group_vibe_empty_error');
    }
    if (value == 'Bad request') {
      return AppLocalizations.tr('group_vibe_bad_request');
    }
    if (value == 'Access denied') {
      return AppLocalizations.tr('group_vibe_access_denied');
    }
    return value;
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.result});

  final GroupVibeCheckResult result;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          sliver: SliverList.list(
            children: [
              _HeaderCard(result: result),
              const SizedBox(height: AppSpacing.lg),
              _RecommendationCard(result: result),
              const SizedBox(height: AppSpacing.lg),
              _BreakdownCard(breakdown: result.breakdown),
              const SizedBox(height: AppSpacing.lg),
              _TopMatchesSection(matches: result.topMatches),
              const SizedBox(height: AppSpacing.lg),
              _InsightListCard(
                title: AppLocalizations.tr('group_strengths'),
                icon: Icons.thumb_up_alt_rounded,
                iconColor: AppColors.success,
                items: result.groupStrengths,
              ),
              const SizedBox(height: AppSpacing.md),
              _InsightListCard(
                title: AppLocalizations.tr('watchouts'),
                icon: Icons.info_rounded,
                iconColor: AppColors.warning,
                items: result.watchouts,
              ),
              const SizedBox(height: AppSpacing.md),
              _InsightListCard(
                title: AppLocalizations.tr('conversation_starters'),
                icon: Icons.chat_bubble_outline_rounded,
                iconColor: AppColors.info,
                items: result.conversationAngles,
              ),
              const SizedBox(height: AppSpacing.md),
              _InsightListCard(
                title: AppLocalizations.tr('suggested_actions'),
                icon: Icons.bolt_rounded,
                iconColor: AppColors.primary,
                items: result.suggestedActions,
              ),
              if (result.insightSource == 'fallback') ...[
                const SizedBox(height: AppSpacing.md),
                _FallbackNotice(reason: result.insightFallbackReason),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.result});

  final GroupVibeCheckResult result;

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(result.overallGroupScore);

    return _SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Text(
            result.matchName,
            textAlign: TextAlign.center,
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${result.groupSize} ${AppLocalizations.tr('members')} - '
            '${AppLocalizations.tr('analyzed')} ${result.analyzedMemberCount}',
            textAlign: TextAlign.center,
            style: AppTextStyles.captionLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: 156,
            height: 156,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 156,
                  height: 156,
                  child: CircularProgressIndicator(
                    value: result.overallGroupScore.clamp(0.0, 1.0).toDouble(),
                    strokeWidth: 11,
                    strokeCap: StrokeCap.round,
                    color: color,
                    backgroundColor: AppColors.bgTertiary,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${result.compatibilityPercentage}%',
                      style: TextStyle(
                        color: color,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        result.vibeLevel,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            result.groupVibeLabel,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMediumSemiBold.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.result});

  final GroupVibeCheckResult result;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: AppLocalizations.tr('group_recommendation_title'),
            icon: Icons.psychology_alt_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            result.summary,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Text(
              result.recommendation,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.breakdown});

  final GroupVibeBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final rows = [
      (
        AppLocalizations.tr('member_compatibility'),
        breakdown.memberCompatibility,
        Icons.groups_2,
      ),
      (
        AppLocalizations.tr('interest_alignment'),
        breakdown.interestAlignment,
        Icons.interests,
      ),
      (
        AppLocalizations.tr('event_fit'),
        breakdown.eventFit,
        Icons.event_available,
      ),
      (
        AppLocalizations.tr('social_comfort'),
        breakdown.socialComfort,
        Icons.volunteer_activism,
      ),
      (AppLocalizations.tr('location_fit'), breakdown.locationFit, Icons.place),
      (
        AppLocalizations.tr('group_reliability'),
        breakdown.groupReliability,
        Icons.verified,
      ),
    ];

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: AppLocalizations.tr('breakdown'),
            icon: Icons.analytics_outlined,
            color: AppColors.accent,
          ),
          const SizedBox(height: AppSpacing.lg),
          ...rows.map(
            (row) => _BreakdownBar(label: row.$1, value: row.$2, icon: row.$3),
          ),
        ],
      ),
    );
  }
}

class _TopMatchesSection extends StatelessWidget {
  const _TopMatchesSection({required this.matches});

  final List<GroupVibeMemberMatch> matches;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: AppLocalizations.tr('top_matches_in_group'),
            icon: Icons.favorite_rounded,
            color: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.md),
          if (matches.isEmpty)
            Text(
              AppLocalizations.tr('no_group_top_matches'),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            ...matches.map((match) => _TopMatchTile(match: match)),
        ],
      ),
    );
  }
}

class _TopMatchTile extends StatelessWidget {
  const _TopMatchTile({required this.match});

  final GroupVibeMemberMatch match;

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(match.score);

    return InkWell(
      onTap: match.userId.isEmpty
          ? null
          : () => context.router.push(PublicProfileRoute(userId: match.userId)),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            VibeAvatar(
              imageUrl: match.avatarUrl,
              name: match.name,
              size: 48,
              showBorder: false,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          match.name.isEmpty
                              ? AppLocalizations.tr('member')
                              : match.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMediumSemiBold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${(match.score * 100).round()}%',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: color,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    match.reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.captionLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightListCard extends StatelessWidget {
  const _InsightListCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title, icon: icon, color: iconColor),
          const SizedBox(height: AppSpacing.md),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackNotice extends StatelessWidget {
  const _FallbackNotice({this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.offline_bolt_rounded, color: AppColors.textHint),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              reason == null
                  ? AppLocalizations.tr('fallback_insight_computed')
                  : '${AppLocalizations.tr('fallback_insight_prefix')}: $reason',
              style: AppTextStyles.captionLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownBar extends StatelessWidget {
  const _BreakdownBar({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final double value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(value);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: AppTextStyles.captionLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${(value * 100).round()}%',
                      style: AppTextStyles.captionLarge.copyWith(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 7,
                    value: value.clamp(0.0, 1.0).toDouble(),
                    color: color,
                    backgroundColor: AppColors.bgTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.bodyMediumSemiBold.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppSpacing.shadowSmall,
      ),
      child: child,
    );
  }
}

Color _scoreColor(double score) {
  if (score >= 0.75) return AppColors.success;
  if (score >= 0.50) return AppColors.warning;
  return AppColors.error;
}
