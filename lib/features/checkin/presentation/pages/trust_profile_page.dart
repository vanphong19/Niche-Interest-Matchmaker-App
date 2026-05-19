import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_localizations.dart';
import '../mock/checkin_mock_data.dart';
import '../widgets/checkin_scaffold.dart';
import '../widgets/trust_activity_tile.dart';
import '../widgets/trust_badge_tile.dart';
import '../widgets/trust_score_card.dart';
import '../widgets/trust_stat_tile.dart';

@RoutePage()
class TrustProfilePage extends StatelessWidget {
  const TrustProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CheckinScaffold(
      title: 'Trust Profile',
      leadingIcon: Icons.arrow_back_rounded,
      onLeadingPressed: () => Navigator.of(context).maybePop(),
      activeTab: CheckinShellTab.trust,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TrustScoreCard(),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: TrustStatTile(
                        icon: Icons.event_available_rounded,
                        value: '95%',
                        label: AppLocalizations.tr('checkin_attendance_rate'),
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TrustStatTile(
                        icon: Icons.local_fire_department_rounded,
                        value: '5',
                        label: AppLocalizations.tr('checkin_meetup_streak'),
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _SectionHeader(
                  title: AppLocalizations.tr('activity_history'),
                  action: AppLocalizations.tr('view_all'),
                ),
                const SizedBox(height: AppSpacing.md),
                for (final item in CheckinMockData.trustActivities) ...[
                  TrustActivityTile(item: item),
                  const SizedBox(height: AppSpacing.sm),
                ],
                const SizedBox(height: AppSpacing.lg),
                _SectionHeader(
                  title: AppLocalizations.tr('checkin_earned_badges'),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 146,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: CheckinMockData.badges.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.md),
                    itemBuilder: (context, index) {
                      return TrustBadgeTile(
                        item: CheckinMockData.badges[index],
                      );
                    },
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.headingSmall.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: () {},
            child: Text(action!),
          ),
      ],
    );
  }
}
