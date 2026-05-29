import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_localizations.dart';
import '../checkin_session.dart';
import '../mock/checkin_mock_data.dart';
import '../widgets/checkin_scaffold.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_action_button.dart';
import '../widgets/nfc_pulse_target.dart';
import 'trust_profile_page.dart';

@RoutePage()
class NfcCheckinResultPage extends StatelessWidget {
  const NfcCheckinResultPage({
    super.key,
    this.method = 'QR Check-in',
  });

  final String method;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CheckinScaffold(
      title: 'Check-in Complete',
      leadingIcon: Icons.close_rounded,
      onLeadingPressed: () => Navigator.of(context).maybePop(),
      showBottomNav: false,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  const NfcPulseTarget(resultMode: true),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    AppLocalizations.tr('checkin_nfc_result_title'),
                    style: AppTextStyles.displayMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'You have successfully checked in.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  GlassCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(
                                  alpha: 0.14,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusLarge,
                                ),
                              ),
                              child: const Icon(
                                Icons.verified_user_rounded,
                                color: AppColors.success,
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
                                        .copyWith(
                                      color: colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    AppLocalizations.tr('checkin_xp_awarded'),
                                    style:
                                        AppTextStyles.captionMedium.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Divider(
                          color: colorScheme.outline.withValues(alpha: 0.42),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Icon(
                              Icons.qr_code_2_rounded,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Method: $method',
                                style: AppTextStyles.captionMedium.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  GradientActionButton(
                    label: AppLocalizations.tr('checkin_view_trust'),
                    icon: Icons.verified_user_rounded,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TrustProfilePage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  GradientActionButton(
                    label: AppLocalizations.tr('done'),
                    secondary: true,
                    onPressed: () {
                      CheckinSession.markCheckedIn();
                      Navigator.of(context).popUntil(
                        (route) {
                          final routeName = route.settings.name;
                          return routeName == 'CheckinDetailRoute' ||
                              (routeName?.contains('CheckinDetail') ?? false) ||
                              route.isFirst;
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
