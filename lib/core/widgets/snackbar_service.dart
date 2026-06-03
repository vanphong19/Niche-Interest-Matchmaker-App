// lib/core/widgets/snackbar_service.dart
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum SnackBarType { success, error, warning, info }

class VibeSnackBar {
  VibeSnackBar._();

  static final List<_SnackRequest> _queue = [];
  static OverlayEntry? _activeEntry;
  static bool _isShowing = false;

  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final displayMessage = _cleanMessage(message);
    _queue.add(
      _SnackRequest(
        message: displayMessage,
        type: type,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
      ),
    );
    _showNext(context);
  }

  static void _showNext(BuildContext context) {
    if (_isShowing || _queue.isEmpty) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    _isShowing = true;
    final request = _queue.removeAt(0);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _VibeSnackBarWidget(
        message: request.message,
        type: request.type,
        actionLabel: request.actionLabel,
        onAction: request.onAction,
        duration: request.duration,
        onDismiss: () {
          if (entry.mounted) entry.remove();
          if (_activeEntry == entry) _activeEntry = null;
          _isShowing = false;
          _showNext(context);
        },
      ),
    );

    overlay.insert(entry);
    _activeEntry = entry;
  }

  static void success(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.success);
  }

  static void error(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
  }) {
    show(
      context,
      message: message,
      type: SnackBarType.error,
      actionLabel: onRetry != null ? 'Retry' : null,
      onAction: onRetry,
    );
  }

  static void warning(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.warning);
  }

  static void info(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.info);
  }

  static String _cleanMessage(String message) {
    var value = message.trim();
    final prefixes = [
      'Exception: ',
      'ServerException: ',
      'NetworkException: ',
      'AuthException: ',
      'ValidationException: ',
      'TimeoutException: ',
      'CacheException: ',
      'NotFoundException: ',
    ];
    for (final prefix in prefixes) {
      if (value.startsWith(prefix)) {
        value = value.substring(prefix.length).trim();
      }
    }
    final statusIndex = value.indexOf(' (status:');
    if (statusIndex > 0) {
      value = value.substring(0, statusIndex).trim();
    }
    return value.isEmpty ? 'Something went wrong. Please try again.' : value;
  }
}

class VibeFeedback {
  VibeFeedback._();

  static void apiSuccess(BuildContext context, String message) {
    VibeSnackBar.success(context, message);
  }

  static void apiError(
    BuildContext context,
    Object error, {
    VoidCallback? onRetry,
  }) {
    VibeSnackBar.error(context, fromException(error), onRetry: onRetry);
  }

  static String fromException(Object error) {
    return VibeSnackBar._cleanMessage(error.toString());
  }
}

class _SnackRequest {
  const _SnackRequest({
    required this.message,
    required this.type,
    this.actionLabel,
    this.onAction,
    required this.duration,
  });

  final String message;
  final SnackBarType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
}

class _VibeSnackBarWidget extends StatefulWidget {
  const _VibeSnackBarWidget({
    required this.message,
    required this.type,
    this.actionLabel,
    this.onAction,
    required this.duration,
    required this.onDismiss,
  });

  final String message;
  final SnackBarType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final VoidCallback onDismiss;

  @override
  State<_VibeSnackBarWidget> createState() => _VibeSnackBarWidgetState();
}

class _VibeSnackBarWidgetState extends State<_VibeSnackBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  Color get _backgroundColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (widget.type) {
      case SnackBarType.success:
        return isDark ? const Color(0xFF0F2F26) : const Color(0xFFEFFAF5);
      case SnackBarType.error:
        return isDark ? const Color(0xFF3A1518) : const Color(0xFFFFF1F2);
      case SnackBarType.warning:
        return isDark ? const Color(0xFF3A2B12) : const Color(0xFFFFF8E7);
      case SnackBarType.info:
        return isDark ? const Color(0xFF10233F) : const Color(0xFFEEF6FF);
    }
  }

  Color get _accentColor {
    switch (widget.type) {
      case SnackBarType.success:
        return AppColors.success;
      case SnackBarType.error:
        return AppColors.error;
      case SnackBarType.warning:
        return AppColors.warning;
      case SnackBarType.info:
        return AppColors.primary;
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case SnackBarType.success:
        return Icons.check_circle_rounded;
      case SnackBarType.error:
        return Icons.error_rounded;
      case SnackBarType.warning:
        return Icons.warning_rounded;
      case SnackBarType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + AppSpacing.sm,
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! < 0) {
                _dismiss();
              }
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: AppSpacing.borderRadiusMedium,
                  border: Border.all(
                    color: _accentColor.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(_icon, color: _accentColor, size: 22),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextPrimary
                              : AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.actionLabel != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      GestureDetector(
                        onTap: () {
                          widget.onAction?.call();
                          _dismiss();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: AppSpacing.borderRadiusSmall,
                          ),
                          child: Text(
                            widget.actionLabel!,
                            style: AppTextStyles.buttonSmall.copyWith(
                              color: _accentColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: AppSpacing.xs),
                    GestureDetector(
                      onTap: _dismiss,
                      child: Icon(
                        Icons.close_rounded,
                        color: _accentColor,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
