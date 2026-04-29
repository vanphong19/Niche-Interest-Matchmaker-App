import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class MatchMetricBar extends StatelessWidget {
  const MatchMetricBar.progress({
    super.key,
    required this.label,
    required this.icon,
    required this.trailing,
    required this.progress,
    required this.iconColor,
    required this.gradient,
  }) : isSpectrum = false,
       leftHint = null,
       rightHint = null,
       spectrumValue = null,
       spectrumColor = null;

  const MatchMetricBar.spectrum({
    super.key,
    required this.label,
    required this.icon,
    required this.trailing,
    required this.iconColor,
    required this.spectrumValue,
    required this.leftHint,
    required this.rightHint,
    this.spectrumColor,
  }) : isSpectrum = true,
       progress = null,
       gradient = null;

  final String label;
  final IconData icon;
  final String trailing;
  final Color iconColor;

  final bool isSpectrum;

  final double? progress;
  final Gradient? gradient;

  final double? spectrumValue;
  final String? leftHint;
  final String? rightHint;
  final Color? spectrumColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              trailing,
              style: AppTextStyles.captionLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!isSpectrum)
          _ProgressTrack(
            value: progress ?? 0,
            gradient:
                gradient ??
                const LinearGradient(
                  colors: [AppColors.primary, AppColors.accentLight],
                ),
          )
        else
          _SpectrumTrack(
            value: spectrumValue ?? 0,
            activeColor: spectrumColor ?? AppColors.secondary,
            leftHint: leftHint ?? '',
            rightHint: rightHint ?? '',
          ),
      ],
    );
  }
}

class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({required this.value, required this.gradient});

  final double value;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final safe = value.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: SizedBox(
        height: 10,
        child: Stack(
          children: [
            Container(color: AppColors.bgTertiary),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: safe,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: gradient),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpectrumTrack extends StatelessWidget {
  const _SpectrumTrack({
    required this.value,
    required this.activeColor,
    required this.leftHint,
    required this.rightHint,
  });

  final double value;
  final Color activeColor;
  final String leftHint;
  final String rightHint;

  @override
  Widget build(BuildContext context) {
    final safe = value.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                Expanded(
                  flex: ((1 - safe) * 1000).round().clamp(1, 999),
                  child: Container(color: AppColors.bgTertiary),
                ),
                Expanded(
                  flex: (safe * 1000).round().clamp(1, 999),
                  child: Container(color: activeColor),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Text(
              leftHint,
              style: AppTextStyles.captionSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              rightHint,
              style: AppTextStyles.captionSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
