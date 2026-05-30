import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/avatar_widget.dart';

class ParticipantsStack extends StatelessWidget {
  const ParticipantsStack({
    super.key,
    required this.imageUrls,
    required this.extraCount,
  });

  final List<String> imageUrls;
  final int extraCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final avatarSize = width <= 320 ? 32.0 : 40.0;
        final overlap = width <= 320 ? 18.0 : 24.0;
        final maxAvatars = width <= 320 ? 2 : 3;
        final visible = imageUrls.take(maxAvatars).toList();
        final computedExtra = imageUrls.length - visible.length + extraCount;
        final showExtra = computedExtra > 0;
        final stackWidth = showExtra
            ? (visible.length * overlap) + avatarSize
            : (((visible.length - 1) >= 0 ? (visible.length - 1) : 0) *
                      overlap) +
                  avatarSize;

        return SizedBox(
          width: stackWidth,
          height: avatarSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (int i = 0; i < visible.length; i++)
                Positioned(
                  left: i * overlap,
                  child: _AvatarImage(
                    imageUrl: visible[i],
                    borderColor: AppColors.bgPrimary,
                    size: avatarSize,
                  ),
                ),
              if (showExtra)
                Positioned(
                  left: visible.length * overlap,
                  child: CircleAvatar(
                    radius: avatarSize / 2,
                    backgroundColor: AppColors.bgTertiary,
                    child: Text(
                      '+$computedExtra',
                      style: AppTextStyles.captionMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: width <= 320 ? 10 : 11,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({
    required this.imageUrl,
    required this.borderColor,
    required this.size,
  });

  final String imageUrl;
  final Color borderColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return VibeAvatar(
      imageUrl: imageUrl,
      size: size,
      showBorder: true,
      borderColor: borderColor,
      borderWidth: 2,
    );
  }
}
