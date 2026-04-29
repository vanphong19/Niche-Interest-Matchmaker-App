// lib/core/widgets/error_widget.dart
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'vibe_button.dart';

class VibeErrorWidget extends StatefulWidget {
  const VibeErrorWidget({
    super.key,
    this.message = 'Something went wrong',
    this.onRetry,
    this.compact = false,
    this.icon,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool compact;
  final IconData? icon;

  @override
  State<VibeErrorWidget> createState() => _VibeErrorWidgetState();
}

class _VibeErrorWidgetState extends State<VibeErrorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -10.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -10.0, end: 0.0).chain(
          CurveTween(curve: Curves.bounceOut),
        ),
        weight: 75,
      ),
    ]).animate(_controller);

    _controller.repeat(reverse: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: widget.compact
            ? const EdgeInsets.all(AppSpacing.lg)
            : const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _bounceAnimation.value),
                  child: child,
                );
              },
              child: Container(
                width: widget.compact ? 56 : 80,
                height: widget.compact ? 56 : 80,
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    widget.icon ?? Icons.sentiment_dissatisfied_rounded,
                    size: widget.compact ? 28 : 40,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
            SizedBox(height: widget.compact ? AppSpacing.lg : AppSpacing.xxl),
            Text(
              'Oops!',
              style: widget.compact
                  ? AppTextStyles.bodyMediumSemiBold
                  : AppTextStyles.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: 160,
                child: VibeButton(
                  label: 'Try Again',
                  onPressed: widget.onRetry,
                  prefixIcon: Icons.refresh_rounded,
                  type: VibeButtonType.outlined,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
