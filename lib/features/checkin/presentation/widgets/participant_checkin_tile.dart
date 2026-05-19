import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../models/checkin_ui_model.dart';
import 'glass_card.dart';
import 'status_pill.dart';
import 'verification_avatar.dart';

class ParticipantCheckinTile extends StatelessWidget {
  const ParticipantCheckinTile({super.key, required this.participant});

  final CheckinParticipant participant;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final toneColor = checkinToneColor(participant.tone);

    return GlassCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: toneColor.withValues(alpha: 0.75),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppSpacing.radiusXLarge),
                ),
              ),
              child: const SizedBox(width: 5),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    VerificationAvatar(
                      imageUrl: participant.imageUrl,
                      name: participant.name,
                      size: 48,
                      glow: participant.tone == CheckinStatusTone.success,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            participant.name,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            participant.subtitle,
                            style: AppTextStyles.captionLarge.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    StatusPill(
                      label: participant.status,
                      icon: _iconForTone(participant.tone),
                      tone: participant.tone,
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

  IconData _iconForTone(CheckinStatusTone tone) {
    switch (tone) {
      case CheckinStatusTone.success:
        return Icons.check_circle_rounded;
      case CheckinStatusTone.warning:
      case CheckinStatusTone.error:
        return Icons.warning_rounded;
      case CheckinStatusTone.neutral:
        return Icons.hourglass_empty_rounded;
    }
  }
}
