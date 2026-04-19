import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final IconData? icon;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) => _pressController.forward();
  void _handleTapUp(TapUpDetails _) => _pressController.reverse();
  void _handleTapCancel() => _pressController.reverse();

  @override
  Widget build(BuildContext context) {
    final borderColor = AppColors.borderLight;

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: ElevatedButton.icon(
          onPressed: widget.onPressed,
          icon: widget.icon == null
              ? const SizedBox.shrink()
              : Icon(widget.icon, size: 20),
          label: Text(widget.label),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.filled ? AppColors.primary : AppColors.bgPrimary,
            foregroundColor: widget.filled
                ? AppColors.textInverse
                : AppColors.primary,
            elevation: widget.filled ? 1 : 0,
            shadowColor: AppColors.primary.withValues(alpha: 0.25),
            minimumSize: const Size.fromHeight(AppSpacing.buttonHeight + 4),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            textStyle: AppTextStyles.buttonLarge,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              side: widget.filled
                  ? BorderSide.none
                  : BorderSide(color: borderColor),
            ),
          ),
        ),
      ),
    );
  }
}
