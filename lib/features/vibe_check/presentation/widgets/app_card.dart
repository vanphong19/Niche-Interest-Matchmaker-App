import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double scale = _isPressed
        ? 0.985
        : (_isHovering && widget.onTap != null ? 1.01 : 1);
    final double elevation = _isPressed
        ? 1
        : (_isHovering && widget.onTap != null ? 8 : 3);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() {
        _isHovering = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: widget.onTap == null
            ? null
            : (_) => setState(() => _isPressed = true),
        onTapUp: widget.onTap == null
            ? null
            : (_) => setState(() => _isPressed = false),
        onTapCancel: widget.onTap == null
            ? null
            : () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: AppColors.bgPrimary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
              boxShadow: AppSpacing.shadowLarge
                  .map(
                    (shadow) => shadow.copyWith(spreadRadius: elevation / 12),
                  )
                  .toList(),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
