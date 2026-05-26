import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_spacing.dart';
import '../constants/finder_ui_constants.dart';

class FinderActionButton extends StatefulWidget {
  const FinderActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.secondary = false,
    this.destructive = false,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary;
  final bool destructive;
  final bool fullWidth;

  @override
  State<FinderActionButton> createState() => _FinderActionButtonState();
}

class _FinderActionButtonState extends State<FinderActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null;
    final foreground = widget.secondary
        ? (widget.destructive ? colorScheme.error : colorScheme.onSurface)
        : colorScheme.onPrimary;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: enabled
          ? () {
              HapticFeedback.selectionClick();
              widget.onPressed?.call();
            }
          : null,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: FinderUiConstants.fast,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.45,
          duration: FinderUiConstants.fast,
          child: Container(
            width: widget.fullWidth ? double.infinity : null,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: widget.secondary ? colorScheme.surface : null,
              gradient: widget.secondary
                  ? null
                  : LinearGradient(
                      colors: widget.destructive
                          ? [
                              colorScheme.error,
                              colorScheme.error.withValues(alpha: 0.78),
                            ]
                          : [colorScheme.primary, colorScheme.tertiary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              border: widget.secondary
                  ? Border.all(
                      color:
                          (widget.destructive
                                  ? colorScheme.error
                                  : colorScheme.outline)
                              .withValues(alpha: 0.45),
                    )
                  : null,
              boxShadow: widget.secondary
                  ? null
                  : [
                      BoxShadow(
                        color:
                            (widget.destructive
                                    ? colorScheme.error
                                    : colorScheme.primary)
                                .withValues(alpha: 0.20),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: widget.fullWidth
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: foreground, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
