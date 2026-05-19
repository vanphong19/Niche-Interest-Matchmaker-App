import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.borderRadius,
    this.onTap,
    this.opacity = 0.18,
    this.borderOpacity = 0.16,
    this.clip = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final double opacity;
  final double borderOpacity;
  final bool clip;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius =
        widget.borderRadius ?? BorderRadius.circular(AppSpacing.radiusXLarge);
    final scale = _pressed
        ? 0.98
        : (_hovered && widget.onTap != null ? 1.01 : 1.0);

    final card = AnimatedScale(
      scale: scale,
      duration: AppSpacing.animationFast,
      curve: Curves.easeOutCubic,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(
                alpha: _hovered ? 0.10 : 0.06,
              ),
              blurRadius: _hovered ? 32 : 22,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: colorScheme.shadow.withValues(
                alpha: _hovered ? 0.11 : 0.07,
              ),
              blurRadius: _hovered ? 18 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          clipBehavior: widget.clip ? Clip.antiAlias : Clip.none,
          child: AnimatedContainer(
            duration: AppSpacing.animationFast,
            padding: widget.padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surface,
                  colorScheme.surface,
                  colorScheme.primaryContainer.withValues(alpha: 0.22),
                ],
              ),
              borderRadius: radius,
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.34),
              ),
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: radius,
              border: Border(
                top: BorderSide(
                  color: colorScheme.onPrimary.withValues(alpha: 0.55),
                ),
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.onTap == null) {
      return card;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: card,
      ),
    );
  }
}
