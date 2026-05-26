import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'finder_map_background.dart';

class FinderScaffold extends StatelessWidget {
  const FinderScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.showBack = true,
    this.extendBody = false,
    this.background,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final bool showBack;
  final bool extendBody;
  final Widget? background;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      extendBody: extendBody,
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          Positioned.fill(child: background ?? const FinderMapBackground()),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                FinderTopBar(
                  title: title,
                  subtitle: subtitle,
                  showBack: showBack,
                  trailing: trailing,
                ),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FinderTopBar extends StatelessWidget {
  const FinderTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          if (showBack)
            _FrostedIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onPressed: () => context.router.maybePop(),
            )
          else
            const SizedBox(width: 44),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTextStyles.captionMedium.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          trailing ?? const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _FrostedIconButton extends StatelessWidget {
  const _FrostedIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          color: colorScheme.onSurface,
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.surface.withValues(alpha: 0.78),
            fixedSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
