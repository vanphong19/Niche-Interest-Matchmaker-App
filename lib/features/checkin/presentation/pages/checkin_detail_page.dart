import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_localizations.dart';
import '../checkin_session.dart';
import '../mock/checkin_mock_data.dart';
import '../models/checkin_event_details.dart';
import '../widgets/checkin_scaffold.dart';
import '../widgets/event_hero_card.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_action_button.dart';
import '../widgets/location_preview_card.dart';
import '../widgets/participant_checkin_tile.dart';
import 'checkin_method_page.dart';

@RoutePage()
class CheckinDetailPage extends StatelessWidget {
  const CheckinDetailPage({super.key, this.matchId, this.eventDetails});

  final String? matchId;
  final CheckinEventDetails? eventDetails;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final details =
        eventDetails ?? CheckinEventDetails.fallback(matchId: matchId);

    return CheckinScaffold(
      title: AppLocalizations.tr('checkin_feature_title'),
      leadingIcon: Icons.arrow_back_rounded,
      onLeadingPressed: () => Navigator.of(context).maybePop(),
      activeTab: CheckinShellTab.meetups,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EventHeroCard(details: details),
            const SizedBox(height: AppSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 720;
                final location = LocationPreviewCard(details: details);
                final actions = ValueListenableBuilder<Set<String>>(
                  valueListenable: CheckinSession.checkedInMatchIds,
                  builder: (context, _, _) {
                    return _CheckinActionPanel(
                      checkedIn: CheckinSession.isCheckedIn(details.matchId),
                      onCheckin: () {
                        if (!details.hasMatchContext) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.tr('checkin_missing_context'),
                              ),
                            ),
                          );
                          return;
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                CheckinMethodPage(eventDetails: details),
                          ),
                        );
                      },
                    );
                  },
                );
                if (!wide) {
                  return Column(
                    children: [
                      location,
                      const SizedBox(height: AppSpacing.lg),
                      actions,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: location),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(flex: 2, child: actions),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.tr('checkin_participants'),
                    style: AppTextStyles.headingSmall.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  AppLocalizations.tr('checkin_confirmed_count'),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            for (final participant in CheckinMockData.participants) ...[
              ParticipantCheckinTile(participant: participant),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _CheckinActionPanel extends StatelessWidget {
  const _CheckinActionPanel({required this.checkedIn, required this.onCheckin});

  final bool checkedIn;
  final VoidCallback onCheckin;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (checkedIn) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.10),
                borderRadius: AppSpacing.borderRadiusLarge,
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.22),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    color: AppColors.success,
                    size: 42,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppLocalizations.tr('checkin_checked_in_title'),
                    style: AppTextStyles.headingSmall.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    AppLocalizations.tr('checkin_checked_in_desc'),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ] else ...[
            Text(
              AppLocalizations.tr('checkin_required_note'),
              style: AppTextStyles.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            GradientActionButton(
              label: AppLocalizations.tr('checkin_check_in'),
              icon: Icons.verified_user_rounded,
              onPressed: onCheckin,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Row(
            children: [
              Expanded(
                child: GradientActionButton(
                  label: AppLocalizations.tr('checkin_chat'),
                  icon: Icons.chat_bubble_rounded,
                  secondary: true,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: GradientActionButton(
                  label: AppLocalizations.tr('checkin_map'),
                  icon: Icons.map_rounded,
                  secondary: true,
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.10),
              borderRadius: AppSpacing.borderRadiusMedium,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      AppLocalizations.tr('checkin_auto_verify_note'),
                      style: AppTextStyles.captionMedium.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
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
