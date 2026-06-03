import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/widgets/vibe_header.dart';

@RoutePage()
class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

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
        title: AppLocalizations.tr('terms_service'),
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
              _buildSectionTitle('1. Acceptance of Terms', textColor),
              _buildSectionBody(
                'By accessing and using VibePulse, you agree to be bound by these Terms of Service and all applicable laws and regulations. If you do not agree with any of these terms, you are prohibited from using or accessing this app.',
                secondaryTextColor,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('2. Use License', textColor),
              _buildSectionBody(
                'Permission is granted to temporarily download one copy of the materials (information or software) on VibePulse\'s app for personal, non-commercial transitory viewing only.',
                secondaryTextColor,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('3. User Conduct', textColor),
              _buildSectionBody(
                'Users are responsible for their own interactions and content. Harassment, illegal activities, and violation of others\' privacy are strictly prohibited and may lead to account termination.',
                secondaryTextColor,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('4. Privacy', textColor),
              _buildSectionBody(
                'Your use of VibePulse is also governed by our Privacy Policy. Please review our Privacy Policy, which also governs the app and informs users of our data collection practices.',
                secondaryTextColor,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('5. Disclaimer', textColor),
              _buildSectionBody(
                'The materials on VibePulse\'s app are provided on an \'as is\' basis. VibePulse makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties including, without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property or other violation of rights.',
                secondaryTextColor,
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'Thank you for using VibePulse!',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
