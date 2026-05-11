import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
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
        title: 'Match Details',
        showBack: true,
        translucent: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'More',
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
                    return const Column(
                      children: [
                        MatchInsightCard(
                          title: 'Strengths',
                          description:
                              'Strong match in sports. Both prefer high-intensity weekend activities and share similar skill levels in tennis.',
                          leadingIcon: Icons.check_circle,
                          leadingBg: AppColors.successLight,
                          leadingFg: AppColors.secondary,
                          emphasisColor: AppColors.secondary,
                        ),
                        SizedBox(height: AppSpacing.md),
                        MatchInsightCard(
                          title: 'Considerations',
                          description:
                              'Contains 2 new users to the platform. Less historical data available for schedule reliability.',
                          leadingIcon: Icons.info,
                          leadingBg: AppColors.errorLight,
                          leadingFg: AppColors.error,
                          emphasisColor: AppColors.warning,
                        ),
                      ],
                    );
                  }

                  return const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: MatchInsightCard(
                          title: 'Strengths',
                          description:
                              'Strong match in sports. Both prefer high-intensity weekend activities and share similar skill levels in tennis.',
                          leadingIcon: Icons.check_circle,
                          leadingBg: AppColors.successLight,
                          leadingFg: AppColors.secondary,
                          emphasisColor: AppColors.secondary,
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: MatchInsightCard(
                          title: 'Considerations',
                          description:
                              'Contains 2 new users to the platform. Less historical data available for schedule reliability.',
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
          'Vibe Match',
          style: AppTextStyles.headingLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'High compatibility found',
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
        children: const [
          Text('Compatibility Deep Dive', style: AppTextStyles.headingSmall),
          SizedBox(height: AppSpacing.lg),
          MatchMetricBar.progress(
            label: 'Interests',
            icon: Icons.interests_rounded,
            trailing: '90%',
            progress: 0.90,
            iconColor: AppColors.primary,
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.accentLight],
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          MatchMetricBar.spectrum(
            label: 'Activity Style',
            icon: Icons.directions_run,
            trailing: 'Competitive',
            iconColor: AppColors.secondary,
            spectrumValue: 0.7,
            leftHint: 'Casual',
            rightHint: 'Intense',
            spectrumColor: AppColors.secondary,
          ),
          SizedBox(height: AppSpacing.lg),
          MatchMetricBar.progress(
            label: 'Schedule Match',
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
          const Text(
            'How you compare to group',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              const Expanded(
                child: _StatBlock(
                  title: 'Your Score',
                  value: '85',
                  valueColor: AppColors.primary,
                  alignEnd: false,
                ),
              ),
              Container(width: 1, height: 42, color: AppColors.borderLight),
              const Expanded(
                child: _StatBlock(
                  title: 'Group Avg',
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
                'You are in the top 15% for this group',
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
                  'Avg',
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
