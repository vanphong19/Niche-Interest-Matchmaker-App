// lib/core/widgets/vibe_confirm_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import 'vibe_button.dart';

/// Shows a beautiful, custom, theme-aware confirmation or info dialog.
///
/// Has high-end rounded corners, elegant circular header icons with soft backings,
/// and clear hierarchy highlighting primary actions vs secondary actions.
/// If [cancelLabel] is null, displays a clean single-button Info style layout.
Future<bool?> showVibeConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  IconData? icon,
  Color? iconBgColor,
  Color? iconColor,
  bool isDestructive = false,
}) {
  HapticFeedback.mediumImpact();
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: isDark ? const Color(0xFF161D2A) : Colors.white,
      surfaceTintColor: Colors.transparent,
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Elegant Header Icon with soft backing circular background
          if (icon != null) ...[
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: iconBgColor ??
                    (isDestructive
                        ? (isDark
                            ? const Color(0xFF381E21)
                            : const Color(0xFFFFEAEA))
                        : (isDark
                            ? const Color(0xFF1B2A47)
                            : const Color(0xFFE8F2FF))),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: iconColor ??
                      (isDestructive
                          ? AppColors.error
                          : const Color(0xFF278DFF)),
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Message
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          // Action Buttons: Cancel/Secondary on left if present, Confirm/Primary on right
          Row(
            children: [
              if (cancelLabel != null) ...[
                Expanded(
                  child: VibeButton(
                    label: cancelLabel,
                    type: VibeButtonType.secondary,
                    onPressed: () => Navigator.pop(context, false),
                    height: 48,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: VibeButton(
                  label: confirmLabel,
                  type: isDestructive
                      ? VibeButtonType.danger
                      : VibeButtonType.primary,
                  onPressed: () => Navigator.pop(context, true),
                  height: 48,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
