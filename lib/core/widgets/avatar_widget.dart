// lib/core/widgets/avatar_widget.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class VibeAvatar extends StatelessWidget {
  const VibeAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 48,
    this.showOnlineIndicator = false,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2.5,
    this.onTap,
    this.heroTag,
  });

  final String? imageUrl;
  final String? name;
  final double size;
  final bool showOnlineIndicator;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;
  final String? heroTag;

  String get _initials {
    if (name == null || name!.trim().isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Color get _initialsColor {
    if (name == null || name!.trim().isEmpty) return const Color(0xFF6366F1); // Indigo default
    final hash = name!.codeUnits.fold<int>(0, (prev, el) => prev + el);
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFFEC4899), // Pink
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
      const Color(0xFF3B82F6), // Blue
    ];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    Widget avatar = _buildAvatar();

    if (heroTag != null) {
      avatar = Hero(tag: heroTag!, child: avatar);
    }

    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    if (showOnlineIndicator) {
      return Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return avatar;
  }

  Widget _buildAvatar() {
    String? resolvedUrl = imageUrl;
    if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
      if (resolvedUrl.contains('dicebear.com') && resolvedUrl.contains('/svg')) {
        resolvedUrl = resolvedUrl.replaceAll('/svg', '/png');
      }
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: borderColor ?? AppColors.primary,
                width: borderWidth,
              )
            : null,
        boxShadow: showBorder ? AppSpacing.shadowSmall : null,
      ),
      child: ClipOval(
        child: resolvedUrl != null && resolvedUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: resolvedUrl,
                fit: BoxFit.cover,
                width: size,
                height: size,
                placeholder: (_, _) => _buildPlaceholder(),
                errorWidget: (_, _, _) => _buildInitials(),
              )
            : _buildInitials(),
      ),
    );
  }

  Widget _buildInitials() {
    final color = _initialsColor;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withValues(alpha: 0.65),
          ],
        ),
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            fontSize: size * 0.38,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.bgTertiary,
      child: Center(
        child: SizedBox(
          width: size * 0.3,
          height: size * 0.3,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
