import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../router/app_router.gr.dart';
import '../mock/finder_mock_data.dart';
import '../models/finder_participant_ui_model.dart';
import '../widgets/finder_action_button.dart';
import '../widgets/finder_glass_panel.dart';
import '../widgets/finder_map_background.dart';
import '../widgets/finder_participant_avatar.dart';
import '../widgets/finder_scaffold.dart';
import '../widgets/finder_status_pill.dart';

@RoutePage()
class FindInCrowdMeetingPage extends StatelessWidget {
  const FindInCrowdMeetingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = FinderMockData.session;
    final colorScheme = Theme.of(context).colorScheme;

    return FinderScaffold(
      title: AppLocalizations.tr('finder_title'),
      subtitle: session.locationName,
      background: const FinderMapBackground(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FinderGlassPanel(
              radius: 32,
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FinderStatusPill(
                    label: 'Upcoming Meeting',
                    icon: Icons.event_available_rounded,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    session.title,
                    style: AppTextStyles.displayMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _InfoRow(
                    icon: Icons.schedule_rounded,
                    label: session.timeLabel,
                  ),
                  _InfoRow(
                    icon: Icons.location_on_rounded,
                    label: session.locationAddress,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FinderGlassPanel(
              child: Row(
                children: [
                  FinderParticipantAvatar(
                    imageUrl: session.partner.avatarUrl,
                    name: session.partner.name,
                    pulsing: true,
                    accentColor: AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meeting with',
                          style: AppTextStyles.captionMedium.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          session.partner.fullName,
                          style: AppTextStyles.headingSmall.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          session.meetingNote,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.call_rounded),
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Participants',
              style: AppTextStyles.headingSmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final participant in session.participants) ...[
              _ParticipantTile(participant: participant),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.lg),
            FinderActionButton(
              label: AppLocalizations.tr('finder_find_in_crowd'),
              icon: Icons.my_location_rounded,
              onPressed: () => context.router.push(const FinderStartRoute()),
            ),
            const SizedBox(height: AppSpacing.sm),
            FinderActionButton(
              label: 'Preview incoming request',
              icon: Icons.radar_rounded,
              secondary: true,
              onPressed: () =>
                  context.router.push(const FinderIncomingRequestRoute()),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({required this.participant});

  final FinderParticipantUiModel participant;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FinderGlassPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          FinderParticipantAvatar(
            imageUrl: participant.avatarUrl,
            name: participant.name,
            size: 46,
            accentColor: participant.accentColor,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.fullName,
                  style: AppTextStyles.bodyMediumSemiBold.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  participant.subtitle,
                  style: AppTextStyles.captionMedium.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          FinderStatusPill(
            label: participant.statusLabel,
            icon: Icons.circle,
            color: participant.accentColor,
          ),
        ],
      ),
    );
  }
}
