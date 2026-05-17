// lib/core/widgets/vibe_button.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'vibe_loading.dart';

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
    this.fontSize,
    this.iconSize,
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
  final double? fontSize;
  final double? iconSize;

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
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
        return Transform.scale(scale: _scaleAnimation.value, child: child);
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
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF278DFF), Color(0xFF165DD9)],
              )
            : const LinearGradient(
                colors: [Color(0xFF8EB4DE), Color(0xFF9EC0E4)],
              ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(child: _buildContent(Colors.white)),
    );
  }

  Widget _buildSecondary(double height) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: widget.width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: _buildContent(
          isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildOutlined(double height) {
    return Container(
      width: widget.width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF278DFF), width: 1.5),
      ),
      child: Center(child: _buildContent(const Color(0xFF278DFF))),
    );
  }

  Widget _buildText() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: _buildContent(const Color(0xFF278DFF)),
    );
  }

  Widget _buildDanger(double height) {
    return Container(
      width: widget.width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(child: _buildContent(Colors.white)),
    );
  }

  Widget _buildContent(Color textColor) {
    if (widget.isLoading) {
      return VibeLoading(size: 20, strokeWidth: 2.5, color: textColor);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.prefixIcon != null) ...[
          Icon(
            widget.prefixIcon,
            size: widget.iconSize ?? 18,
            color: textColor,
          ),
          const SizedBox(width: 8),
        ],
        Text(
          widget.label,
          style: AppTextStyles.buttonMedium.copyWith(
            color: textColor,
            fontSize: widget.fontSize ?? 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
        if (widget.suffixIcon != null) ...[
          const SizedBox(width: 8),
          Icon(
            widget.suffixIcon,
            size: widget.iconSize ?? 18,
            color: textColor,
          ),
        ],
      ],
    );
  }
}
