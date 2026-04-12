// lib/core/widgets/vibe_button.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum VibeButtonType { primary, secondary, outlined, text, danger }

class VibeButton extends StatefulWidget {
  const VibeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = VibeButtonType.primary,
    this.isLoading = false,
    this.isDisabled = false,
    this.prefixIcon,
    this.suffixIcon,
    this.width,
    this.height,
  });

  final String label;
  final VoidCallback? onPressed;
  final VibeButtonType type;
  final bool isLoading;
  final bool isDisabled;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final double? width;
  final double? height;

  @override
  State<VibeButton> createState() => _VibeButtonState();
}

class _VibeButtonState extends State<VibeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isInteractive =>
      !widget.isLoading && !widget.isDisabled && widget.onPressed != null;

  void _handleTapDown(TapDownDetails details) {
    if (_isInteractive) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isInteractive) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  void _handleTap() {
    if (_isInteractive) {
      HapticFeedback.lightImpact();
      widget.onPressed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _handleTap,
        child: AnimatedOpacity(
          opacity: widget.isDisabled ? 0.5 : 1.0,
          duration: AppSpacing.animationFast,
          child: _buildButton(),
        ),
      ),
    );
  }

  Widget _buildButton() {
    final h = widget.height ?? AppSpacing.buttonHeight;

    switch (widget.type) {
      case VibeButtonType.primary:
        return _buildPrimary(h);
      case VibeButtonType.secondary:
        return _buildSecondary(h);
      case VibeButtonType.outlined:
        return _buildOutlined(h);
      case VibeButtonType.text:
        return _buildText();
      case VibeButtonType.danger:
        return _buildDanger(h);
    }
  }

  Widget _buildPrimary(double height) {
    return Container(
      width: widget.width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: _isInteractive
            ? AppColors.primaryGradient
            : const LinearGradient(
                colors: [Color(0xFFAAABFF), Color(0xFFBBBCFF)],
              ),
        borderRadius: AppSpacing.borderRadiusLarge,
        boxShadow: _isInteractive
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Center(child: _buildContent(AppColors.textInverse)),
    );
  }

  Widget _buildSecondary(double height) {
    return Container(
      width: widget.width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: AppSpacing.borderRadiusLarge,
      ),
      child: Center(child: _buildContent(AppColors.textPrimary)),
    );
  }

  Widget _buildOutlined(double height) {
    return Container(
      width: widget.width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: AppSpacing.borderRadiusLarge,
        border: Border.all(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
      child: Center(child: _buildContent(AppColors.primary)),
    );
  }

  Widget _buildText() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: _buildContent(AppColors.primary),
    );
  }

  Widget _buildDanger(double height) {
    return Container(
      width: widget.width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: AppSpacing.borderRadiusLarge,
      ),
      child: Center(child: _buildContent(AppColors.textInverse)),
    );
  }

  Widget _buildContent(Color textColor) {
    if (widget.isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: textColor,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.prefixIcon != null) ...[
          Icon(widget.prefixIcon, size: 20, color: textColor),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          widget.label,
          style: AppTextStyles.buttonLarge.copyWith(color: textColor),
        ),
        if (widget.suffixIcon != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(widget.suffixIcon, size: 20, color: textColor),
        ],
      ],
    );
  }
}
