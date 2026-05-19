import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../mock/checkin_mock_data.dart';
import '../widgets/checkin_scaffold.dart';
import '../widgets/glass_card.dart';
import '../widgets/verification_loading_overlay.dart';
import 'nfc_checkin_result_page.dart';

@RoutePage()
class CheckinVerifyingPage extends StatefulWidget {
  const CheckinVerifyingPage({
    super.key,
    this.method = 'QR Check-in',
  });

  final String method;

  @override
  State<CheckinVerifyingPage> createState() => _CheckinVerifyingPageState();
}

class _CheckinVerifyingPageState extends State<CheckinVerifyingPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => NfcCheckinResultPage(method: widget.method),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CheckinScaffold(
      title: 'Verifying Check-in',
      leadingIcon: Icons.close_rounded,
      onLeadingPressed: () => Navigator.of(context).maybePop(),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusXLarge,
                      ),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          CheckinMockData.eventImage,
                          fit: BoxFit.cover,
                          color: colorScheme.onSurface.withValues(alpha: 0.18),
                          colorBlendMode: BlendMode.darken,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GlassCard(
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMedium,
                            ),
                          ),
                          child: Icon(
                            Icons.event_rounded,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                CheckinMockData.eventTitle,
                                style: AppTextStyles.bodyMediumSemiBold
                                    .copyWith(color: colorScheme.onSurface),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${CheckinMockData.eventTime} - ${CheckinMockData.locationName}',
                                style: AppTextStyles.captionMedium.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.82),
            ),
            child: const SizedBox.expand(),
          ),
          const VerificationLoadingOverlay(),
        ],
      ),
    );
  }
}
