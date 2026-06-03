import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_localizations.dart';
import 'glass_card.dart';

class VerificationLoadingOverlay extends StatefulWidget {
  const VerificationLoadingOverlay({super.key});

  @override
  State<VerificationLoadingOverlay> createState() =>
      _VerificationLoadingOverlayState();
}

class _VerificationLoadingOverlayState
    extends State<VerificationLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _controller,
              child: Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.32),
                    width: 9,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: AppColors.primary,
                  size: 46,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              AppLocalizations.tr('checkin_verifying_title'),
              style: AppTextStyles.headingMedium.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppLocalizations.tr('checkin_verifying_desc'),
              style: AppTextStyles.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _TrustCue(
                  icon: Icons.location_on_rounded,
                  label: AppLocalizations.tr('checkin_gps_active'),
                  color: AppColors.success,
                ),
                _TrustCue(
                  icon: Icons.lock_rounded,
                  label: AppLocalizations.tr('checkin_encrypted'),
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustCue extends StatelessWidget {
  const _TrustCue({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      opacity: 0.24,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.captionMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
