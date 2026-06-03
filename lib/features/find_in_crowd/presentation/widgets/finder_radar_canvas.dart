import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_localizations.dart';
import '../constants/finder_ui_constants.dart';
import '../models/finder_location_ui_model.dart';
import '../models/finder_participant_ui_model.dart';
import 'finder_participant_avatar.dart';

class FinderRadarCanvas extends StatefulWidget {
  const FinderRadarCanvas({
    super.key,
    required this.participant,
    required this.currentUserAvatarUrl,
    this.size = FinderUiConstants.radarSize,
    this.showLabel = true,
    this.navigation,
  });

  final FinderParticipantUiModel participant;
  final String currentUserAvatarUrl;
  final double size;
  final bool showLabel;
  final FinderNavigationUiModel? navigation;

  @override
  State<FinderRadarCanvas> createState() => _FinderRadarCanvasState();
}

class _FinderRadarCanvasState extends State<FinderRadarCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final navigation = widget.navigation;
    final targetOffset = navigation == null
        ? Offset(widget.size * 0.62, widget.size * 0.24)
        : _targetOffsetFor(navigation);
    final targetLeft = targetOffset.dx - 39;
    final targetTop = targetOffset.dy - 39;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(widget.size),
            painter: _RadarRingPainter(
              primary: colorScheme.primary,
              outline: colorScheme.outline,
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Transform.rotate(
                angle: _controller.value * math.pi * 2,
                child: CustomPaint(
                  size: Size.square(widget.size),
                  painter: _RadarSweepPainter(color: colorScheme.primary),
                ),
              );
            },
          ),
          if (navigation != null)
            CustomPaint(
              size: Size.square(widget.size),
              painter: _RadarConnectionPainter(
                color: colorScheme.primary,
                relativeBearingDegrees: navigation.relativeBearingDegrees,
                target: targetOffset,
              ),
            ),
          Positioned(
            left: targetLeft,
            top: targetTop,
            child: Column(
              children: [
                FinderParticipantAvatar(
                  imageUrl: widget.participant.avatarUrl,
                  name: widget.participant.name,
                  size: 54,
                  pulsing: true,
                  accentColor: widget.participant.accentColor,
                ),
                if (widget.showLabel) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.86),
                      borderRadius: AppSpacing.borderRadiusPill,
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Text(
                      widget.participant.name,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          FinderParticipantAvatar(
            imageUrl: widget.currentUserAvatarUrl,
            name: AppLocalizations.tr('finder_you'),
            size: 48,
            accentColor: colorScheme.primary,
          ),
          if (navigation == null)
            Positioned(
              bottom: widget.size * 0.18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.88),
                  borderRadius: AppSpacing.borderRadiusPill,
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.20),
                  ),
                ),
                child: Text(
                  AppLocalizations.tr('finder_waiting_shared_location'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Offset _targetOffsetFor(FinderNavigationUiModel navigation) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final cappedDistance = navigation.distanceMeters.clamp(4.0, 60.0);
    final radius = widget.size * (0.18 + (cappedDistance / 60.0) * 0.25);
    final radians = (navigation.relativeBearingDegrees - 90) * math.pi / 180;

    return center + Offset(math.cos(radians), math.sin(radians)) * radius;
  }
}

class _RadarRingPainter extends CustomPainter {
  const _RadarRingPainter({required this.primary, required this.outline});

  final Color primary;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = outline.withValues(alpha: 0.34);
    final axisPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = primary.withValues(alpha: 0.18);

    for (final radius in [
      size.width * 0.18,
      size.width * 0.32,
      size.width * 0.46,
    ]) {
      canvas.drawCircle(center, radius, ringPaint);
    }
    canvas.drawLine(
      Offset(center.dx, 12),
      Offset(center.dx, size.height - 12),
      axisPaint,
    );
    canvas.drawLine(
      Offset(12, center.dy),
      Offset(size.width - 12, center.dy),
      axisPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RadarRingPainter oldDelegate) {
    return oldDelegate.primary != primary || oldDelegate.outline != outline;
  }
}

class _RadarSweepPainter extends CustomPainter {
  const _RadarSweepPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.30),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.10, 0.22],
      ).createShader(rect);
    canvas.drawCircle(size.center(Offset.zero), size.width * 0.46, paint);
  }

  @override
  bool shouldRepaint(covariant _RadarSweepPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _RadarConnectionPainter extends CustomPainter {
  const _RadarConnectionPainter({
    required this.color,
    required this.relativeBearingDegrees,
    required this.target,
  });

  final Color color;
  final double relativeBearingDegrees;
  final Offset target;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final delta = target - center;
    final distance = delta.distance;
    if (distance <= 1) return;

    final direction = delta / distance;
    final start = center + direction * 36;
    final end = target - direction * 40;
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.48)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawLine(start, end, linePaint);

    final arrowCenter = Offset.lerp(start, end, 0.58)!;
    final angle = (relativeBearingDegrees - 90) * math.pi / 180;
    const arrowLength = 16.0;
    const arrowWidth = 11.0;
    final tip =
        arrowCenter + Offset(math.cos(angle), math.sin(angle)) * arrowLength;
    final left =
        arrowCenter +
        Offset(
              math.cos(angle + math.pi * 0.72),
              math.sin(angle + math.pi * 0.72),
            ) *
            arrowWidth;
    final right =
        arrowCenter +
        Offset(
              math.cos(angle - math.pi * 0.72),
              math.sin(angle - math.pi * 0.72),
            ) *
            arrowWidth;

    final arrow = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    canvas.drawPath(arrow, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarConnectionPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.relativeBearingDegrees != relativeBearingDegrees ||
        oldDelegate.target != target;
  }
}
