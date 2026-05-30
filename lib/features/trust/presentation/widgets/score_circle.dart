// lib/features/trust/presentation/widgets/score_circle.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../domain/services/reputation_service.dart';

/// Vòng tròn progress hiển thị điểm uy tín với animation
class ScoreCircle extends StatefulWidget {
  const ScoreCircle({
    super.key,
    required this.score,
    this.size = 160,
    this.strokeWidth = 12,
  });

  final int score;
  final double size;
  final double strokeWidth;

  @override
  State<ScoreCircle> createState() => _ScoreCircleState();
}

class _ScoreCircleState extends State<ScoreCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnim = Tween<double>(
      begin: 0,
      end: widget.score / 100,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final levelData = ReputationService.getLevel(widget.score);

    return AnimatedBuilder(
      animation: _progressAnim,
      builder: (_, __) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _ScoreArcPainter(
              progress: _progressAnim.value,
              colors: levelData.gradientColors,
              strokeWidth: widget.strokeWidth,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(widget.score * _progressAnim.value).round()}',
                    style: TextStyle(
                      fontSize: widget.size * 0.26,
                      fontWeight: FontWeight.w900,
                      color: levelData.color,
                      letterSpacing: -2,
                    ),
                  ),
                  Text(
                    '/ 100',
                    style: TextStyle(
                      fontSize: widget.size * 0.1,
                      fontWeight: FontWeight.w600,
                      color: levelData.color.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ScoreArcPainter extends CustomPainter {
  _ScoreArcPainter({
    required this.progress,
    required this.colors,
    required this.strokeWidth,
  });

  final double progress;
  final List<Color> colors;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = math.pi * 0.7;
    const sweepFull = math.pi * 1.6; // 288 degrees

    // Track (background arc)
    final trackPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepFull,
      false,
      trackPaint,
    );

    if (progress <= 0) return;

    // Gradient progress arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepFull,
      colors: colors,
      tileMode: TileMode.clamp,
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      startAngle,
      sweepFull * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreArcPainter old) =>
      old.progress != progress;
}
