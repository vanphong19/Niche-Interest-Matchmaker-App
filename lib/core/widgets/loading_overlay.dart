// lib/core/widgets/loading_overlay.dart
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'vibe_loading.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingWidget,
    this.color,
    this.blur = 3.0,
  });

  final Widget child;
  final bool isLoading;
  final Widget? loadingWidget;
  final Color? color;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        AnimatedSwitcher(
          duration: AppSpacing.animationNormal,
          child: isLoading
              ? _LoadingLayer(
                  color: color,
                  blur: blur,
                  loadingWidget: loadingWidget,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _LoadingLayer extends StatelessWidget {
  const _LoadingLayer({
    this.color,
    required this.blur,
    this.loadingWidget,
  });

  final Color? color;
  final double blur;
  final Widget? loadingWidget;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          color: (color ?? AppColors.bgPrimary).withValues(alpha: 0.5),
          child: Center(
            child: loadingWidget ??
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: BoxDecoration(
                    color: AppColors.bgPrimary,
                    borderRadius: AppSpacing.borderRadiusXLarge,
                    boxShadow: AppSpacing.shadowLarge,
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VibeLoading(
                        size: 40,
                        strokeWidth: 3,
                        color: AppColors.primary,
                        segments: 12,
                      ),
                      SizedBox(height: AppSpacing.lg),
                      Text(
                        'Loading...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        ),
      ),
    );
  }
}
