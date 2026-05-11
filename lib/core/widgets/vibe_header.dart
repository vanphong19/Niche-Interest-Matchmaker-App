import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:auto_route/auto_route.dart';
import '../theme/app_colors.dart';

class VibeHeader extends StatelessWidget implements PreferredSizeWidget {
  const VibeHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.bottom,
    this.showBackButton = true,
    this.onBackTap,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool showBackButton;
  final VoidCallback? onBackTap;

  static const double headerHeight = 64.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xFF0E121A).withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.5);
    final statusBrightness = isDark ? Brightness.light : Brightness.dark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.secondary;

    final bottomWidget = bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: statusBrightness,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: bgColor,
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: headerHeight,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Absolute Centered Title
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 60),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                if (subtitle != null)
                                  Text(
                                    subtitle!,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.textHint,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Left Action (Back Button)
                        if (showBackButton)
                          Positioned(
                            left: 20,
                            child: VibeHeaderButton(
                              icon: Icons.arrow_back_ios_new_rounded,
                              onTap:
                                  onBackTap ??
                                  () {
                                    HapticFeedback.selectionClick();
                                    context.router.maybePop();
                                  },
                              isDark: isDark,
                            ),
                          ),

                        // Right Actions
                        if (actions != null)
                          Positioned(
                            right: 20,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: actions!,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // ignore: use_null_aware_elements
                  if (bottomWidget != null) bottomWidget,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize {
    double height = headerHeight;
    if (bottom != null) {
      height += bottom!.preferredSize.height;
    }
    return Size.fromHeight(height);
  }
}

class VibeHeaderButton extends StatelessWidget {
  const VibeHeaderButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [], // Explicitly no shadow
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color.fromARGB(231, 241, 245, 249),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color.fromARGB(225, 226, 232, 240),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 19,
              color:
                  color ??
                  (isDark ? AppColors.darkTextPrimary : AppColors.secondary),
            ),
          ),
        ),
      ),
    );
  }
}
