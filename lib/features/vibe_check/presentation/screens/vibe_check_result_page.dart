import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
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
      create: (_) => sl<VibeCheckBloc>()
        ..add(PerformVibeCheck(userId)),
      child: _VibeCheckResultBody(userId: userId),
    );
  }
}

class _VibeCheckResultBody extends StatelessWidget {
  const _VibeCheckResultBody({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: VibeAppBar(
        title: 'Vibe Check',
        showBack: true,
        translucent: true,
      ),
      body: SafeArea(
        child: BlocBuilder<VibeCheckBloc, VibeCheckState>(
          builder: (context, state) {
            if (state is VibeCheckLoading) return const _LoadingView();
            if (state is VibeCheckError) {
              return _ErrorView(message: state.message, colorScheme: colorScheme);
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: colorScheme.primary),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'AI đang phân tích vibe...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'So sánh sở thích, bio và hơn thế nữa',
            style: AppTextStyles.bodySmall.copyWith(
              color: colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.colorScheme});
  final String message;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Oops!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Quay lại'),
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
          CircleAvatar(
            radius: 48,
            backgroundImage: result.targetUserAvatar.isNotEmpty
                ? NetworkImage(result.targetUserAvatar)
                : null,
            backgroundColor: colorScheme.surfaceContainerHighest,
            child: result.targetUserAvatar.isEmpty
                ? Text(
                    result.targetUserName.isNotEmpty
                        ? result.targetUserName[0]
                        : '?',
                    style: TextStyle(
                      fontSize: 36,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Vibe với ${result.targetUserName}',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          _VibeScoreGauge(score: result.overallScore, level: result.vibeLevel),
          const SizedBox(height: AppSpacing.lg),
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                result.summary,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _BreakdownSection(breakdown: result.breakdown),
          const SizedBox(height: AppSpacing.lg),
          if (result.commonInterests.isNotEmpty) ...[
            _CommonInterestsSection(interests: result.commonInterests),
            const SizedBox(height: AppSpacing.lg),
          ],
          _InsightSection(
            title: 'Điểm mạnh',
            icon: Icons.thumb_up_rounded,
            iconColor: Colors.green,
            items: result.strengths,
          ),
          const SizedBox(height: AppSpacing.md),
          _InsightSection(
            title: 'Cần lưu ý',
            icon: Icons.info_rounded,
            iconColor: Colors.orange,
            items: result.risks,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (result.conversationStarters.isNotEmpty) ...[
            _SectionCard(
              title: 'Mở đầu cuộc trò chuyện',
              icon: Icons.chat_bubble_outline_rounded,
              items: result.conversationStarters,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (result.suggestedDateIdeas.isNotEmpty) ...[
            _SectionCard(
              title: 'Gợi ý đi chơi',
              icon: Icons.event_rounded,
              items: result.suggestedDateIdeas,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Đóng'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.event_rounded),
                  label: const Text('Mời đi chơi'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
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
              value: score,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
      ('Sở thích', breakdown.interests, Icons.interests_rounded),
      ('Bio', breakdown.bio, Icons.person_outline_rounded),
      ('Lifestyle', breakdown.lifestyle, Icons.home_rounded),
      ('Event', breakdown.eventPreference, Icons.event_rounded),
      ('Địa điểm', breakdown.location, Icons.location_on_rounded),
      ('Uy tín', breakdown.reputation, Icons.verified_rounded),
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
              'Chi tiết điểm số',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...items.map((item) => _BreakdownBar(
                  label: item.$1,
                  value: item.$2,
                  icon: item.$3,
                )),
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
                    value: value,
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
          'Sở thích chung',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: interests
              .map((interest) => Chip(
                    label: Text(interest),
                    backgroundColor: colorScheme.primaryContainer,
                    labelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
                    side: BorderSide.none,
                  ))
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
            ...items.map((item) => Padding(
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
                )),
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
            ...items.map((item) => Padding(
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
                )),
          ],
        ),
      ),
    );
  }
}
