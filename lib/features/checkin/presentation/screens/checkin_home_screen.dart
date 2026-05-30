import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
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
      title: 'Check-in',
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
                        'Check-in method',
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
                      label: const Text('Verified'),
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
                  'Choose the fastest available option at the venue.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                CheckinMethodCard(
                  option: _qrOption,
                  title: 'QR Check-in',
                  subtitle: 'Scan the event QR code with your camera.',
                  badge: 'Recommended',
                  footnote: 'Best for hosted events and check-in desks.',
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
                  title: 'NFC Check-in',
                  subtitle: 'Hold your phone near the event NFC tag.',
                  badge: 'Tap to verify',
                  footnote: 'Works when NFC is enabled on your device.',
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
