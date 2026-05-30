import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/widgets/vibe_header.dart';

@RoutePage()
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBgPrimary : const Color(0xFFF5F7FF);
    final cardColor = isDark ? AppColors.darkCardBackground : Colors.white;
    final textColor = isDark ? AppColors.darkTextPrimary : const Color(0xFF1B2A57);
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : const Color(0xFF4B5563);

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: VibeHeader(
        title: AppLocalizations.tr('privacy_policy'),
        subtitle: '${AppLocalizations.tr('last_updated')}: May 2026',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.viewPaddingOf(context).top + VibeHeader.headerHeight + 20,
          20,
          40,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('1. Information Collection', textColor),
              _buildSectionBody(
                'We collect information you provide directly to us, such as when you create or modify your account, request on-demand services, contact customer support, or otherwise communicate with us.',
                secondaryTextColor,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('2. Use of Information', textColor),
              _buildSectionBody(
                'We use the information we collect to provide, maintain, and improve our services, develop new features, and protect VibePulse and our users.',
                secondaryTextColor,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('3. Sharing of Information', textColor),
              _buildSectionBody(
                'We may share the information we collect about you as described in this statement or at the time of collection or sharing, including with other users as part of the core functionality of our matchmaker service.',
                secondaryTextColor,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('4. Data Security', textColor),
              _buildSectionBody(
                'We use reasonable measures to help protect information about you from loss, theft, misuse and unauthorized access, disclosure, alteration and destruction.',
                secondaryTextColor,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('5. Your Choices', textColor),
              _buildSectionBody(
                'You may update, correct or delete information about you at any time by logging into your online account. If you wish to delete your account, please use the delete account feature in the settings.',
                secondaryTextColor,
              ),
              const SizedBox(height: 32),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Your privacy is our priority.',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSectionBody(String body, Color color) {
    return Text(
      body,
      style: TextStyle(
        fontSize: 14,
        height: 1.6,
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
