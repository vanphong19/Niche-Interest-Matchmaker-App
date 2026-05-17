import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../theme/app_colors.dart';
import 'vibe_button.dart';

class VibeEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final String? lottieAsset;
  final VoidCallback? onAction;
  final String? actionLabel;
  final bool compact;

  const VibeEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.lottieAsset,
    this.onAction,
    this.actionLabel,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? Colors.white.withValues(alpha: 0.065)
        : Colors.white.withValues(alpha: 0.78);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.11)
        : Colors.white.withValues(alpha: 0.9);
    final shadow = isDark
        ? Colors.black.withValues(alpha: 0.22)
        : const Color(0xFF1C2C58).withValues(alpha: 0.08);

    final panelPadding = compact
        ? const EdgeInsets.fromLTRB(16, 14, 16, 14)
        : const EdgeInsets.fromLTRB(22, 22, 22, 22);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 560),
      padding: panelPadding,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(compact ? 20 : 28),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: compact ? 18 : 34,
            offset: Offset(0, compact ? 8 : 18),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 50 : 64,
            height: compact ? 50 : 64,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color.fromARGB(157, 247, 250, 255),
              borderRadius: BorderRadius.circular(compact ? 17 : 22),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : const Color(0xFFEAF0FB),
              ),
            ),
            child: lottieAsset != null
                ? Padding(
                    padding: const EdgeInsets.all(6),
                    child: Lottie.asset(lottieAsset!),
                  )
                : Icon(
                    icon ?? Icons.inbox_rounded,
                    size: compact ? 24 : 30,
                    color: AppColors.primary,
                  ),
          ),
          SizedBox(height: compact ? 12 : 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 15 : 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.secondary,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 12.5 : 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.38,
            ),
          ),
          if (onAction != null && actionLabel != null) ...[
            SizedBox(height: compact ? 14 : 18),
            SizedBox(
              width: compact ? 160 : 190,
              child: VibeButton(
                label: actionLabel!,
                onPressed: onAction,
                height: compact ? 42 : 46,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
