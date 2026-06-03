import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../core/widgets/vibe_app_bar.dart';
import '../../../../injection/injection_container.dart';
import '../../domain/entities/vibe_check_result.dart';
import '../../domain/entities/vibe_score_breakdown.dart';
import '../bloc/vibe_check_bloc.dart';
import '../bloc/vibe_check_event.dart';
import '../bloc/vibe_check_state.dart';

@RoutePage()
@Injectable()
class VibeCheckResultPage extends StatelessWidget {
  const VibeCheckResultPage({
    super.key,
    @QueryParam('targetUserId') this.targetUserId,
    @QueryParam('targetUserName') this.targetUserName,
  });

  final String? targetUserId;
  final String? targetUserName;

  @override
  Widget build(BuildContext context) {
    final userId = targetUserId ?? '';
    return BlocProvider(
      create: (_) => sl<VibeCheckBloc>()..add(PerformVibeCheck(userId)),
      child: const _VibeCheckResultBody(),
    );
  }
}

class _VibeCheckResultBody extends StatelessWidget {
  const _VibeCheckResultBody();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: VibeAppBar(
        title: AppLocalizations.tr('vibe_check_title'),
        showBack: true,
        translucent: true,
      ),
      body: SafeArea(
        child: BlocBuilder<VibeCheckBloc, VibeCheckState>(
          builder: (context, state) {
            if (state is VibeCheckLoading) return const _LoadingView();
            if (state is VibeCheckError) {
              return _ErrorView(message: state.message);
            }
            if (state is VibeCheckSuccess) {
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
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: AppSpacing.xl),
            Text(
              AppLocalizations.tr('vibe_check_loading_title'),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppLocalizations.tr('vibe_check_loading_desc'),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: colorScheme.outline,
              ),
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppLocalizations.tr('vibe_check_error_title'),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message.replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.tr('back')),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.result});

  final VibeCheckResult result;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          VibeAvatar(
            imageUrl: result.targetUserAvatar,
            name: result.targetUserName,
            size: 96,
            showBorder: true,
            borderColor: colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${AppLocalizations.tr('vibe_check_with')} ${result.targetUserName}',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          _VibeScoreGauge(score: result.overallScore, level: result.vibeLevel),
          const SizedBox(height: AppSpacing.lg),
          _SummaryCard(summary: result.summary),
          const SizedBox(height: AppSpacing.lg),
          _VerdictSection(result: result),
          const SizedBox(height: AppSpacing.lg),
          _BreakdownSection(breakdown: result.breakdown),
          if (result.commonInterests.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _CommonInterestsSection(interests: result.commonInterests),
          ],
          const SizedBox(height: AppSpacing.lg),
          _InsightSection(
            title: AppLocalizations.tr('strengths'),
            icon: Icons.thumb_up_rounded,
            iconColor: Colors.green,
            items: result.strengths,
          ),
          const SizedBox(height: AppSpacing.md),
          _InsightSection(
            title: AppLocalizations.tr('considerations'),
            icon: Icons.info_rounded,
            iconColor: Colors.orange,
            items: result.risks,
          ),
          if (result.conversationStarters.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: AppLocalizations.tr('conversation_starters'),
              icon: Icons.chat_bubble_outline_rounded,
              items: result.conversationStarters,
            ),
          ],
          if (result.suggestedDateIdeas.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: AppLocalizations.tr('date_ideas'),
              icon: Icons.event_rounded,
              items: result.suggestedDateIdeas,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: Text(AppLocalizations.tr('close')),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          summary,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: colorScheme.onSurface,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _VerdictSection extends StatelessWidget {
  const _VerdictSection({required this.result});

  final VibeCheckResult result;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final score = result.overallScore;
    final verdictColor = score >= 0.75
        ? Colors.green
        : score >= 0.50
        ? Colors.orange
        : colorScheme.error;
    final verdictLabel = score >= 0.75
        ? AppLocalizations.tr('verdict_strong')
        : score >= 0.50
        ? AppLocalizations.tr('verdict_medium')
        : AppLocalizations.tr('verdict_low');

    final rows = [
      (
        Icons.person_search_rounded,
        AppLocalizations.tr('personality_take'),
        result.personalityTake,
      ),
      (
        Icons.favorite_border_rounded,
        AppLocalizations.tr('compatibility_conclusion'),
        result.compatibilityConclusion,
      ),
      (
        Icons.event_available_rounded,
        AppLocalizations.tr('date_recommendation'),
        result.dateRecommendation,
      ),
      (
        Icons.arrow_forward_rounded,
        AppLocalizations.tr('next_step'),
        result.nextStep,
      ),
    ].where((row) => row.$3.trim().isNotEmpty).toList();

    if (rows.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: verdictColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.psychology_alt_rounded,
                    size: 20,
                    color: verdictColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    AppLocalizations.tr('verdict'),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: verdictColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(
                    verdictLabel,
                    style: AppTextStyles.captionMedium.copyWith(
                      color: verdictColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(row.$1, size: 19, color: colorScheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.$2,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            row.$3,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VibeScoreGauge extends StatelessWidget {
  const _VibeScoreGauge({required this.score, required this.level});

  final double score;
  final String level;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gaugeColor = score >= 0.75
        ? colorScheme.primary
        : score >= 0.50
        ? Colors.orange
        : colorScheme.error;

    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: CircularProgressIndicator(
              value: score.clamp(0.0, 1.0).toDouble(),
              strokeWidth: 10,
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: gaugeColor,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(score * 100).round()}%',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: gaugeColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: gaugeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Text(
                  level,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: gaugeColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BreakdownSection extends StatelessWidget {
  const _BreakdownSection({required this.breakdown});

  final VibeScoreBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final items = [
      (
        AppLocalizations.tr('interests'),
        breakdown.interests,
        Icons.interests_rounded,
      ),
      (
        AppLocalizations.tr('bio_label'),
        breakdown.bio,
        Icons.person_outline_rounded,
      ),
      (
        AppLocalizations.tr('lifestyle'),
        breakdown.lifestyle,
        Icons.home_rounded,
      ),
      (
        AppLocalizations.tr('event'),
        breakdown.eventPreference,
        Icons.event_rounded,
      ),
      (
        AppLocalizations.tr('location'),
        breakdown.location,
        Icons.location_on_rounded,
      ),
      (
        AppLocalizations.tr('reputation'),
        breakdown.reputation,
        Icons.verified_rounded,
      ),
    ];

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.tr('score_breakdown'),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...items.map(
              (item) =>
                  _BreakdownBar(label: item.$1, value: item.$2, icon: item.$3),
            ),
          ],
        ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final barColor = value >= 0.75
        ? colorScheme.primary
        : value >= 0.50
        ? Colors.orange
        : colorScheme.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: barColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: AppTextStyles.labelLarge),
                    Text(
                      '${(value * 100).round()}%',
                      style: AppTextStyles.labelLarge.copyWith(color: barColor),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  child: LinearProgressIndicator(
                    value: value.clamp(0.0, 1.0).toDouble(),
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    color: barColor,
                    minHeight: 6,
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

class _CommonInterestsSection extends StatelessWidget {
  const _CommonInterestsSection({required this.interests});

  final List<String> interests;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.tr('common_interests'),
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: interests
              .map(
                (interest) => Chip(
                  label: Text(interest),
                  backgroundColor: colorScheme.primaryContainer,
                  labelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
                  side: BorderSide.none,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _InsightSection extends StatelessWidget {
  const _InsightSection({
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

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
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
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 26),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
