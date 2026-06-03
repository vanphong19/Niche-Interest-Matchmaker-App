// lib/core/widgets/shimmer_loader.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkShimmerBase : AppColors.shimmerBase,
      highlightColor:
          isDark ? AppColors.darkShimmerHighlight : AppColors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.bgTertiary,
          borderRadius: shape == BoxShape.circle
              ? null
              : (borderRadius ?? AppSpacing.borderRadiusMedium),
          shape: shape,
        ),
      ),
    );
  }
}

class ShimmerListItem extends StatelessWidget {
  const ShimmerListItem({super.key, this.hasAvatar = true, this.lines = 2});

  final bool hasAvatar;
  final int lines;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkShimmerBase : AppColors.shimmerBase,
      highlightColor:
          isDark ? AppColors.darkShimmerHighlight : AppColors.shimmerHighlight,
      child: Padding(
        padding: AppSpacing.listItemPadding,
        child: Row(
          children: [
            if (hasAvatar) ...[
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.bgTertiary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                  lines,
                  (index) => Padding(
                    padding: EdgeInsets.only(
                      bottom: index < lines - 1 ? AppSpacing.sm : 0,
                    ),
                    child: Container(
                      height: index == 0 ? 16 : 12,
                      width: index == 0
                          ? double.infinity
                          : MediaQuery.of(context).size.width * 0.5,
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerCard extends StatelessWidget {
  const ShimmerCard({
    super.key,
    this.height = 200,
    this.hasImage = true,
  });

  final double height;
  final bool hasImage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkShimmerBase : AppColors.shimmerBase,
      highlightColor:
          isDark ? AppColors.darkShimmerHighlight : AppColors.shimmerHighlight,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: AppSpacing.borderRadiusLarge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              Container(
                height: height * 0.55,
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusLarge),
                  ),
                ),
              ),
            Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.bgTertiary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    height: 12,
                    width: MediaQuery.of(context).size.width * 0.6,
                    decoration: BoxDecoration(
                      color: AppColors.bgTertiary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.bgTertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        height: 12,
                        width: 80,
                        decoration: BoxDecoration(
                          color: AppColors.bgTertiary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerProfile extends StatelessWidget {
  const ShimmerProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkShimmerBase : AppColors.shimmerBase,
      highlightColor:
          isDark ? AppColors.darkShimmerHighlight : AppColors.shimmerHighlight,
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.bgTertiary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              height: 20,
              width: 160,
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              height: 14,
              width: 120,
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                3,
                (_) => Column(
                  children: [
                    Container(
                      height: 20,
                      width: 40,
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 12,
                      width: 60,
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
