import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_localizations.dart';
import '../mock/checkin_mock_data.dart';
import '../models/checkin_event_details.dart';
import '../widgets/checkin_method_card.dart';
import '../widgets/checkin_scaffold.dart';
import '../widgets/gps_status_card.dart';
import 'nfc_checkin_waiting_page.dart';
import 'qr_checkin_scanner_page.dart';

@RoutePage()
class CheckinMethodPage extends StatelessWidget {
  const CheckinMethodPage({super.key, this.matchId, this.eventDetails});

  final String? matchId;
  final CheckinEventDetails? eventDetails;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final details =
        eventDetails ?? CheckinEventDetails.fallback(matchId: matchId);

    return CheckinScaffold(
      title: AppLocalizations.tr('checkin_choose_title'),
      leadingIcon: Icons.arrow_back_rounded,
      onLeadingPressed: () => Navigator.of(context).maybePop(),
      activeTab: CheckinShellTab.scan,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xxl,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppLocalizations.tr('checkin_method_title'),
                  style: AppTextStyles.displayMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppLocalizations.tr('checkin_method_subtitle'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
                for (final option in CheckinMockData.methodOptions) ...[
                  CheckinMethodCard(
                    option: option,
                    title: AppLocalizations.tr(option.titleKey),
                    subtitle: AppLocalizations.tr(option.subtitleKey),
                    badge: option.recommended
                        ? AppLocalizations.tr('checkin_recommended_title')
                        : AppLocalizations.tr('checkin_tap_to_verify'),
                    footnote: option.recommended
                        ? AppLocalizations.tr('checkin_qr_method_footnote')
                        : AppLocalizations.tr('checkin_nfc_method_footnote'),
                    onTap: () {
                      final page = option.recommended
                          ? QrCheckinScannerPage(eventDetails: details)
                          : NfcCheckinWaitingPage(eventDetails: details);
                      Navigator.of(
                        context,
                      ).push(MaterialPageRoute<void>(builder: (_) => page));
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                const SizedBox(height: AppSpacing.xl),
                const GpsStatusCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
