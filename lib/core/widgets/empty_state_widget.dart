// lib/core/widgets/empty_state_widget.dart
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'vibe_button.dart';

class VibeEmptyState extends StatelessWidget {
  const VibeEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconWidget,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? iconWidget;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  // ─── Presets ────────────────────────────────────────────────────
  factory VibeEmptyState.noEvents({VoidCallback? onAction}) {
    return VibeEmptyState(
      icon: Icons.event_busy_rounded,
      title: 'No Events Found',
      subtitle: 'There are no events matching your criteria right now. Try broadening your search or create your own!',
      actionLabel: onAction != null ? 'Create Event' : null,
      onAction: onAction,
    );
  }

  factory VibeEmptyState.noConnection({VoidCallback? onRetry}) {
    return VibeEmptyState(
      icon: Icons.wifi_off_rounded,
      title: 'No Connection',
      subtitle: 'Please check your internet connection and try again.',
      actionLabel: onRetry != null ? 'Retry' : null,
      onAction: onRetry,
    );
  }

  factory VibeEmptyState.noResults({String? query}) {
    return VibeEmptyState(
      icon: Icons.search_off_rounded,
      title: 'No Results',
      subtitle: query != null
          ? 'No results found for "$query". Try a different search term.'
          : 'No results found. Try adjusting your filters.',
    );
  }

  factory VibeEmptyState.noNotifications() {
    return const VibeEmptyState(
      icon: Icons.notifications_off_rounded,
      title: 'All Caught Up',
      subtitle: 'You have no new notifications.',
    );
  }

  factory VibeEmptyState.noBadges() {
    return const VibeEmptyState(
      icon: Icons.emoji_events_rounded,
      title: 'No Badges Yet',
      subtitle: 'Start joining and creating events to earn badges!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: compact
            ? const EdgeInsets.all(AppSpacing.lg)
            : const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(context),
            SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xxl),
            Text(
              title,
              style: compact
                  ? AppTextStyles.bodyMediumSemiBold
                  : AppTextStyles.headingMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: 200,
                child: VibeButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  type: VibeButtonType.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    if (iconWidget != null) return iconWidget!;

    final size = compact ? 56.0 : 80.0;
    final iconSize = compact ? 28.0 : 40.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          icon ?? Icons.inbox_rounded,
          size: iconSize,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
