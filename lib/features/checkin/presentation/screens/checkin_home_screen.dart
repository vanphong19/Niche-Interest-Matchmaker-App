import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_localizations.dart';
import '../models/checkin_ui_model.dart';
import '../widgets/checkin_event_summary_card.dart';
import '../widgets/checkin_method_card.dart';
import '../widgets/checkin_scaffold.dart';
import 'nfc_checkin_screen.dart';
import 'qr_checkin_screen.dart';

class CheckinHomeScreen extends StatelessWidget {
  const CheckinHomeScreen({super.key});

  static const _qrOption = CheckinMethodOption(
    titleKey: 'qr',
    subtitleKey: 'qr_desc',
    icon: Icons.qr_code_scanner_rounded,
    recommended: true,
  );

  static const _nfcOption = CheckinMethodOption(
    titleKey: 'nfc',
    subtitleKey: 'nfc_desc',
    icon: Icons.contactless_rounded,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CheckinScaffold(
      title: AppLocalizations.tr('checkin_title'),
      leadingIcon: Icons.arrow_back_rounded,
      onLeadingPressed: () => Navigator.of(context).maybePop(),
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
                const CheckinEventSummaryCard(),
                const SizedBox(height: AppSpacing.lg),
                const CheckinQuickStats(),
                const SizedBox(height: AppSpacing.xxl),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.tr('checkin_method_section'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Chip(
                      avatar: Icon(
                        Icons.lock_rounded,
                        color: colorScheme.primary,
                        size: 16,
                      ),
                      label: Text(
                        AppLocalizations.tr('checkin_verified_label'),
                      ),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: colorScheme.outline),
                      backgroundColor: colorScheme.surface,
                      labelStyle: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppLocalizations.tr('checkin_method_hint'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                CheckinMethodCard(
                  option: _qrOption,
                  title: AppLocalizations.tr('checkin_qr_method'),
                  subtitle: AppLocalizations.tr('checkin_qr_home_desc'),
                  badge: AppLocalizations.tr('checkin_recommended_title'),
                  footnote: AppLocalizations.tr('checkin_qr_home_footnote'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const QrCheckinScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                CheckinMethodCard(
                  option: _nfcOption,
                  title: AppLocalizations.tr('checkin_nfc_method'),
                  subtitle: AppLocalizations.tr('checkin_nfc_home_desc'),
                  badge: AppLocalizations.tr('checkin_tap_to_verify'),
                  footnote: AppLocalizations.tr('checkin_nfc_home_footnote'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const NfcCheckinScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
