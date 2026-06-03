import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/vibe_app_bar.dart';
import '../widgets/app_card.dart';
import '../widgets/match_insight_card.dart';
import '../widgets/match_metric_bar.dart';

@RoutePage()
class MatchDetailsScreen extends StatelessWidget {
  const MatchDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: VibeAppBar(
        title: AppLocalizations.tr('match_details_title'),
        showBack: true,
        translucent: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: AppLocalizations.tr('more'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveLayout(
          small: (context, info) => _Content(info: info),
          medium: (context, info) => _Content(info: info),
          large: (context, info) => _Content(info: info),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.info});

  final ResponsiveInfo info;

  @override
  Widget build(BuildContext context) {
    final horizontal = (info.width * 0.05).clamp(14.0, 34.0);

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
            children: [
              _ScoreHero(score: 0.85),
              SizedBox(height: (info.width * 0.05).clamp(18.0, 30.0)),
              const _DeepDiveSection(),
              const SizedBox(height: AppSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  final split = constraints.maxWidth >= 760;
                  if (!split) {
                    return Column(
                      children: [
                        MatchInsightCard(
                          title: AppLocalizations.tr('strengths'),
                          description: AppLocalizations.tr(
                            'match_strengths_desc',
                          ),
                          leadingIcon: Icons.check_circle,
                          leadingBg: AppColors.successLight,
                          leadingFg: AppColors.secondary,
                          emphasisColor: AppColors.secondary,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        MatchInsightCard(
                          title: AppLocalizations.tr('considerations'),
                          description: AppLocalizations.tr(
                            'match_considerations_desc',
                          ),
                          leadingIcon: Icons.info,
                          leadingBg: AppColors.errorLight,
                          leadingFg: AppColors.error,
                          emphasisColor: AppColors.warning,
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: MatchInsightCard(
                          title: AppLocalizations.tr('strengths'),
                          description: AppLocalizations.tr(
                            'match_strengths_desc',
                          ),
                          leadingIcon: Icons.check_circle,
                          leadingBg: AppColors.successLight,
                          leadingFg: AppColors.secondary,
                          emphasisColor: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: MatchInsightCard(
                          title: AppLocalizations.tr('considerations'),
                          description: AppLocalizations.tr(
                            'match_considerations_desc',
                          ),
                          leadingIcon: Icons.info,
                          leadingBg: AppColors.errorLight,
                          leadingFg: AppColors.error,
                          emphasisColor: AppColors.warning,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              const _CompareSection(),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final safe = score.clamp(0.0, 1.0);

    return Column(
      children: [
        SizedBox(
          width: 172,
          height: 172,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 172,
                height: 172,
                child: CircularProgressIndicator(
                  value: safe,
                  strokeWidth: 9,
                  backgroundColor: AppColors.bgTertiary,
                  color: AppColors.primary,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Container(
                width: 126,
                height: 126,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.bgPrimary,
                  boxShadow: AppSpacing.shadowLarge,
                ),
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${(safe * 100).round()}',
                          style: AppTextStyles.displayLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 44,
                          ),
                        ),
                        TextSpan(
                          text: '%',
                          style: AppTextStyles.headingSmall.copyWith(
                            color: AppColors.accentLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          AppLocalizations.tr('vibe_match_title'),
          style: AppTextStyles.headingLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          AppLocalizations.tr('high_compatibility_found'),
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _DeepDiveSection extends StatelessWidget {
  const _DeepDiveSection();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.tr('compatibility_deep_dive'),
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          MatchMetricBar.progress(
            label: AppLocalizations.tr('interests'),
            icon: Icons.interests_rounded,
            trailing: '90%',
            progress: 0.90,
            iconColor: AppColors.primary,
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.accentLight],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          MatchMetricBar.spectrum(
            label: AppLocalizations.tr('activity_style'),
            icon: Icons.directions_run,
            trailing: AppLocalizations.tr('competitive'),
            iconColor: AppColors.secondary,
            spectrumValue: 0.7,
            leftHint: AppLocalizations.tr('casual'),
            rightHint: AppLocalizations.tr('intense'),
            spectrumColor: AppColors.secondary,
          ),
          const SizedBox(height: AppSpacing.lg),
          MatchMetricBar.progress(
            label: AppLocalizations.tr('schedule_match'),
            icon: Icons.calendar_month_rounded,
            trailing: '75%',
            progress: 0.75,
            iconColor: AppColors.warning,
            gradient: LinearGradient(
              colors: [AppColors.warning, AppColors.warningLight],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareSection extends StatelessWidget {
  const _CompareSection();

  @override
  Widget build(BuildContext context) {
    const yourScore = 0.85;
    const groupAvg = 0.72;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.tr('how_you_compare_to_group'),
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _StatBlock(
                  title: AppLocalizations.tr('your_score'),
                  value: '85',
                  valueColor: AppColors.primary,
                  alignEnd: false,
                ),
              ),
              Container(width: 1, height: 42, color: AppColors.borderLight),
              Expanded(
                child: _StatBlock(
                  title: AppLocalizations.tr('group_avg'),
                  value: '72',
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _CompareTrack(yourScore: yourScore, groupAverage: groupAvg),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Text(
                AppLocalizations.tr('you_top_group'),
                style: AppTextStyles.captionMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.title,
    required this.value,
    this.valueColor = AppColors.textPrimary,
    required this.alignEnd,
  });

  final String title;
  final String value;
  final Color valueColor;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.captionLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.displayMedium.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CompareTrack extends StatelessWidget {
  const _CompareTrack({required this.yourScore, required this.groupAverage});

  final double yourScore;
  final double groupAverage;

  @override
  Widget build(BuildContext context) {
    final yourSafe = yourScore.clamp(0.0, 1.0);
    final avgSafe = groupAverage.clamp(0.0, 1.0);

    return SizedBox(
      height: 42,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final markerX = avgSafe * width;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.bgTertiary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 0,
                width: width * yourSafe,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accentLight],
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: markerX - 1,
                child: Container(
                  width: 2,
                  height: 24,
                  color: AppColors.textSecondary,
                ),
              ),
              Positioned(
                top: 0,
                left: markerX - 12,
                child: Text(
                  AppLocalizations.tr('avg'),
                  style: AppTextStyles.captionSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: (width * yourSafe) - 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.bgPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
