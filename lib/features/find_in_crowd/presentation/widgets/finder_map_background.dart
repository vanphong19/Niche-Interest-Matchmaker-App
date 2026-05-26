import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class FinderMapBackground extends StatelessWidget {
  const FinderMapBackground({
    super.key,
    this.cameraMode = false,
    this.dimmed = false,
  });

  final bool cameraMode;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: cameraMode
                  ? [
                      colorScheme.surface,
                      colorScheme.primaryContainer.withValues(alpha: 0.34),
                      colorScheme.tertiary.withValues(alpha: 0.20),
                    ]
                  : [
                      colorScheme.surface,
                      colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.48,
                      ),
                      colorScheme.primaryContainer.withValues(alpha: 0.28),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        CustomPaint(
          painter: _FinderMapPainter(
            line: colorScheme.outline,
            cameraMode: cameraMode,
          ),
        ),
        if (cameraMode)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.20),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.18),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        if (dimmed) ColoredBox(color: Colors.black.withValues(alpha: 0.24)),
      ],
    );
  }
}

class _FinderMapPainter extends CustomPainter {
  const _FinderMapPainter({
    required this.line,
    required this.cameraMode,
  });

  final Color line;
  final bool cameraMode;

  @override
  void paint(Canvas canvas, Size size) {
    final streetPaint = Paint()
      ..color = line.withValues(alpha: cameraMode ? 0.20 : 0.26)
      ..strokeWidth = cameraMode ? 18 : 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 7; i++) {
      final y = size.height * (0.12 + i * 0.15);
      final path = Path()
        ..moveTo(-40, y)
        ..cubicTo(
          size.width * 0.25,
          y - 50,
          size.width * 0.55,
          y + 70,
          size.width + 40,
          y + math.sin(i) * 34,
        );
      canvas.drawPath(path, streetPaint);
    }

    for (var i = 0; i < 5; i++) {
      final x = size.width * (0.08 + i * 0.22);
      final path = Path()
        ..moveTo(x, -40)
        ..cubicTo(
          x + 70,
          size.height * 0.25,
          x - 60,
          size.height * 0.62,
          x + 30,
          size.height + 40,
        );
      canvas.drawPath(path, streetPaint);
    }

    final dotPaint = Paint()..color = AppColors.success.withValues(alpha: 0.72);
    canvas.drawCircle(
      Offset(size.width * 0.80, size.height * 0.18),
      cameraMode ? 8 : 6,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FinderMapPainter oldDelegate) {
    return oldDelegate.line != line ||
        oldDelegate.cameraMode != cameraMode;
  }
}
