import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class VibeLoading extends StatefulWidget {
  const VibeLoading({
    super.key,
    this.size = 40.0,
    this.strokeWidth = 3.5,
    this.color,
    this.segments = 12,
  });

  final double size;
  final double strokeWidth;
  final Color? color;
  final int segments;

  @override
  State<VibeLoading> createState() => _VibeLoadingState();
}

class _VibeLoadingState extends State<VibeLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return RotationTransition(
          turns: _controller,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _DashedCircularPainter(
              color: color,
              strokeWidth: widget.strokeWidth,
              segments: widget.segments,
            ),
          ),
        );
      },
    );
  }
}

class _DashedCircularPainter extends CustomPainter {
  _DashedCircularPainter({
    required this.color,
    required this.strokeWidth,
    required this.segments,
  });

  final Color color;
  final double strokeWidth;
  final int segments;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final double segmentAngle = (2 * math.pi) / segments;
    const double gapRatio = 0.45; // 45% gap between segments

    for (int i = 0; i < segments; i++) {
      // Create a fading effect for the segments to look like a trail
      final double segmentOpacity = (i + 1) / segments;
      final double startAngle = i * segmentAngle;
      final double sweepAngle = segmentAngle * (1 - gapRatio);

      paint.color = color.withValues(alpha: segmentOpacity.clamp(0.1, 1.0));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCircularPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.segments != segments;
  }
}
