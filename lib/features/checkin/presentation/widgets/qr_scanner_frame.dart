import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class QrScannerFrame extends StatefulWidget {
  const QrScannerFrame({super.key});

  @override
  State<QrScannerFrame> createState() => _QrScannerFrameState();
}

class _QrScannerFrameState extends State<QrScannerFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth;
          return Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.darkTextPrimary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusXLarge,
                      ),
                      border: Border.all(
                        color: AppColors.darkTextPrimary.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      color: AppColors.darkTextPrimary.withValues(alpha: 0.14),
                      size: size * 0.28,
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final top = AppSpacing.xl +
                      (_controller.value * (size - AppSpacing.xl * 2));
                  return Positioned(
                    left: AppSpacing.xl,
                    right: AppSpacing.xl,
                    top: top,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.success,
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.6),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const _ScannerCorner(alignment: Alignment.topLeft),
              const _ScannerCorner(alignment: Alignment.topRight),
              const _ScannerCorner(alignment: Alignment.bottomLeft),
              const _ScannerCorner(alignment: Alignment.bottomRight),
            ],
          );
        },
      ),
    );
  }
}

class _ScannerCorner extends StatelessWidget {
  const _ScannerCorner({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment.x < 0;
    final isTop = alignment.y < 0;
    return Align(
      alignment: alignment,
      child: Container(
        width: 42,
        height: 42,
        margin: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: AppColors.success, width: 4)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: AppColors.success, width: 4)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: AppColors.success, width: 4)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: AppColors.success, width: 4)
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: isLeft && isTop
                ? const Radius.circular(AppSpacing.radiusLarge)
                : Radius.zero,
            topRight: !isLeft && isTop
                ? const Radius.circular(AppSpacing.radiusLarge)
                : Radius.zero,
            bottomLeft: isLeft && !isTop
                ? const Radius.circular(AppSpacing.radiusLarge)
                : Radius.zero,
            bottomRight: !isLeft && !isTop
                ? const Radius.circular(AppSpacing.radiusLarge)
                : Radius.zero,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withValues(alpha: 0.28),
              blurRadius: 14,
            ),
          ],
        ),
      ),
    );
  }
}
