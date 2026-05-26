import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../models/finder_participant_ui_model.dart';
import 'finder_action_button.dart';
import 'finder_glass_panel.dart';
import 'finder_participant_avatar.dart';
import 'finder_status_pill.dart';

class FinderStartPanel extends StatelessWidget {
  const FinderStartPanel({
    super.key,
    required this.participant,
    required this.onStart,
    required this.onCancel,
  });

  final FinderParticipantUiModel participant;
  final VoidCallback onStart;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FinderGlassPanel(
      radius: 32,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FinderParticipantAvatar(
            imageUrl: participant.avatarUrl,
            name: participant.name,
            size: 76,
            pulsing: true,
            accentColor: participant.accentColor,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Find ${participant.name} in the crowd?',
            style: AppTextStyles.headingMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'You and ${participant.name} will share approximate locations temporarily to find each other faster.',
            style: AppTextStyles.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          const FinderSafetyNotice(),
          const SizedBox(height: AppSpacing.lg),
          FinderActionButton(
            label: 'Start Finding',
            icon: Icons.my_location_rounded,
            onPressed: onStart,
          ),
          const SizedBox(height: AppSpacing.sm),
          FinderActionButton(
            label: 'Cancel',
            secondary: true,
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

class FinderRequestPanel extends StatelessWidget {
  const FinderRequestPanel({
    super.key,
    required this.participant,
    required this.onAccept,
    required this.onDecline,
  });

  final FinderParticipantUiModel participant;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FinderGlassPanel(
      radius: 32,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FinderParticipantAvatar(
                imageUrl:
                    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=300',
                name: 'You',
                size: 62,
              ),
              Container(
                width: 58,
                height: 2,
                color: colorScheme.primary.withValues(alpha: 0.32),
              ),
              FinderParticipantAvatar(
                imageUrl: participant.avatarUrl,
                name: participant.name,
                size: 62,
                pulsing: true,
                accentColor: participant.accentColor,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '${participant.name} wants to find you in the crowd',
            style: AppTextStyles.headingSmall.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${participant.name} wants to share temporary approximate locations so you can find each other faster.',
            style: AppTextStyles.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          const FinderSafetyNotice(),
          const SizedBox(height: AppSpacing.lg),
          FinderActionButton(
            label: 'Share Temporary Location',
            icon: Icons.location_on_rounded,
            onPressed: onAccept,
          ),
          const SizedBox(height: AppSpacing.sm),
          FinderActionButton(
            label: 'Not Now',
            secondary: true,
            onPressed: onDecline,
          ),
        ],
      ),
    );
  }
}

class FinderConfirmationPanel extends StatelessWidget {
  const FinderConfirmationPanel({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.icon,
    required this.onPrimary,
    required this.onSecondary,
    this.destructive = false,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final String secondaryLabel;
  final IconData icon;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tone = destructive ? colorScheme.error : colorScheme.primary;
    return FinderGlassPanel(
      radius: 32,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: tone, size: 34),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: AppTextStyles.headingMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTextStyles.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          FinderActionButton(
            label: primaryLabel,
            icon: icon,
            destructive: destructive,
            onPressed: onPrimary,
          ),
          const SizedBox(height: AppSpacing.sm),
          FinderActionButton(
            label: secondaryLabel,
            secondary: true,
            onPressed: onSecondary,
          ),
        ],
      ),
    );
  }
}

class FinderSafetyNotice extends StatelessWidget {
  const FinderSafetyNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.10),
        borderRadius: AppSpacing.borderRadiusLarge,
      ),
      child: Column(
        children: [
          FinderStatusPill(
            label: 'For finding only',
            icon: Icons.shield_rounded,
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Temporary sharing ends automatically after 10 minutes. You can stop anytime.',
            style: AppTextStyles.captionMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
