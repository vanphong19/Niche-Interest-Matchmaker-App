import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_localizations.dart';
import '../mock/checkin_mock_data.dart';
import 'glass_card.dart';

class LocationPreviewCard extends StatelessWidget {
  const LocationPreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 210,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primaryContainer.withValues(alpha: 0.24),
                      colorScheme.surface,
                      colorScheme.tertiaryContainer.withValues(alpha: 0.12),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(painter: _MapPatternPainter(colorScheme)),
            ),
            Center(
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surface,
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.32),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: colorScheme.primary,
                  size: 38,
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.lg,
              child: GlassCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                borderRadius: AppSpacing.borderRadiusLarge,
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: colorScheme.tertiary.withValues(alpha: 0.12),
                        borderRadius: AppSpacing.borderRadiusMedium,
                      ),
                      child: Icon(
                        Icons.place_rounded,
                        color: colorScheme.tertiary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppLocalizations.tr('checkin_meeting_point'),
                            style: AppTextStyles.captionSmall.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            CheckinMockData.locationName,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      style: IconButton.styleFrom(
                        backgroundColor:
                            colorScheme.primary.withValues(alpha: 0.10),
                      ),
                      icon: Icon(
                        Icons.directions_rounded,
                        color: colorScheme.primary,
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

class _MapPatternPainter extends CustomPainter {
  const _MapPatternPainter(this.colorScheme);

  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colorScheme.outline.withValues(alpha: 0.18)
      ..strokeWidth = 1.5;
    final accent = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.28)
      ..strokeWidth = 3;
    final secondary = Paint()
      ..color = colorScheme.tertiary.withValues(alpha: 0.22)
      ..strokeWidth = 2.5;

    for (double x = -40; x < size.width + 40; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x + 80, size.height), paint);
    }
    for (double y = 28; y < size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 30), paint);
    }
    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.78),
      Offset(size.width * 0.92, size.height * 0.22),
      accent,
    );
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.18),
      Offset(size.width * 0.86, size.height * 0.74),
      secondary,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
