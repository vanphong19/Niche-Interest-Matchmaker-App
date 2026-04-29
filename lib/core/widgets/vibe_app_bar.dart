// lib/core/widgets/vibe_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class VibeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const VibeAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.showBack = true,
    this.onBack,
    this.backgroundColor,
    this.centerTitle = true,
    this.leading,
    this.elevation = 0,
    this.bottom,
    this.translucent = false,
  });

  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool showBack;
  final VoidCallback? onBack;
  final Color? backgroundColor;
  final bool centerTitle;
  final Widget? leading;
  final double elevation;
  final PreferredSizeWidget? bottom;
  final bool translucent;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final bgColor = backgroundColor ??
        (translucent
            ? Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9)
            : Theme.of(context).scaffoldBackgroundColor);

    return AppBar(
      backgroundColor: bgColor,
      elevation: elevation,
      scrolledUnderElevation: translucent ? 0 : 0.5,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      systemOverlayStyle: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      leading: leading ??
          (showBack && canPop
              ? _buildBackButton(context)
              : null),
      title: titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: AppTextStyles.bodyMediumSemiBold.copyWith(
                    fontSize: 17,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                )
              : null),
      actions: actions != null
          ? [
              ...actions!,
              const SizedBox(width: 4),
            ]
          : null,
      bottom: bottom,
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (onBack != null) {
          onBack!();
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.bgTertiary.withValues(alpha: 0.8),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            Icons.chevron_left_rounded,
            size: 28,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
