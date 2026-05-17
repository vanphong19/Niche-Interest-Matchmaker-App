import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/widgets/vibe_header.dart';

@RoutePage()
class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  static const _faqItems = [
    (
      question: 'How do I join a vibe?',
      answer:
          'Browse the home feed, open a vibe that fits your plans, then tap JOIN. Public vibes join instantly while approval-only vibes notify the host.',
    ),
    (
      question: 'Can I host my own event?',
      answer:
          'Yes. Use the create button in the main navigation, add the category, time, location, cover photo, and participant limit, then publish it.',
    ),
    (
      question: 'How does matchmaking work?',
      answer:
          'VibePulse compares your interests, location, activity history, and event preferences to highlight people and vibes that are more relevant to you.',
    ),
    (
      question: 'Is my location shared?',
      answer:
          'Your location helps rank nearby vibes. Other users do not see your exact address, and you can update location permissions from settings.',
    ),
    (
      question: 'How do I report a user?',
      answer:
          'Open the user profile, choose Report, and submit the issue. Reports are reviewed so the community stays safe and respectful.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBgPrimary : const Color(0xFFF5F7FF);

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: VibeHeader(
        title: AppLocalizations.tr('help_center'),
        subtitle: AppLocalizations.tr('faq_support'),
        showBackButton: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.viewPaddingOf(context).top + VibeHeader.headerHeight + 20,
          20,
          40,
        ),
        children: [
          _HelpIntro(isDark: isDark),
          const SizedBox(height: 18),
          _SearchField(isDark: isDark),
          const SizedBox(height: 18),
          _QuickActions(isDark: isDark),
          const SizedBox(height: 24),
          Text(
            'Popular questions',
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.secondary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          ..._faqItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FAQCard(
                question: item.question,
                answer: item.answer,
                isDark: isDark,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SupportCard(isDark: isDark),
        ],
      ),
    );
  }
}

class _HelpIntro extends StatelessWidget {
  const _HelpIntro({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.darkGradient
            : const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFEAF5FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFDDEAF8),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help?',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.secondary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Find quick answers or reach support when something needs a closer look.',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onTap: HapticFeedback.selectionClick,
      textAlignVertical: TextAlignVertical.center,
      style: TextStyle(
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        constraints: const BoxConstraints(
          maxHeight: 45,
        ),
        hintText: 'Search articles, safety, events...',
        hintStyle: TextStyle(
          color: isDark ? AppColors.darkTextHint : AppColors.textHint,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          width: 46,
          alignment: Alignment.center,
          child: const Icon(
            Icons.search_rounded,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 0,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.2,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final items = [
      (icon: Icons.event_available_rounded, label: 'Events'),
      (icon: Icons.verified_user_rounded, label: 'Safety'),
      (icon: Icons.location_on_rounded, label: 'Location'),
    ];

    return Row(
      children: items.map((item) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: item == items.last ? 0 : 10),
            child: _QuickActionTile(
              icon: item.icon,
              label: item.label,
              isDark: isDark,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: HapticFeedback.selectionClick,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 86,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBackground : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.borderLight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FAQCard extends StatelessWidget {
  const _FAQCard({
    required this.question,
    required this.answer,
    required this.isDark,
  });

  final String question;
  final String answer;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: AppColors.primary.withValues(alpha: 0.06),
        highlightColor: Colors.transparent,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.borderLight,
          ),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          iconColor: AppColors.primary,
          collapsedIconColor: isDark
              ? AppColors.darkTextSecondary
              : AppColors.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            question,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.secondary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 34),
          const SizedBox(height: 10),
          const Text(
            'Still need help?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Our support team is available 24/7 to assist you.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: HapticFeedback.mediumImpact,
              icon: const Icon(Icons.chat_bubble_rounded, size: 18),
              label: const Text('Contact Support'),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
