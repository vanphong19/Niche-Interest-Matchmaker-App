// lib/features/settings/presentation/pages/settings_page.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_localizations.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';

@RoutePage()
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _emailNotifs = true;
  bool _pushNotifs = true;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBgPrimary : const Color(0xFFF5F7FF);
    final cardColor = isDark ? AppColors.darkCardBackground : Colors.white;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : const Color(0xFF1B2A57);
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : const Color(0xFF233363);
    final subtitleColor = isDark ? AppColors.darkTextHint : Colors.grey[500]!;
    final dividerColor = isDark
        ? AppColors.darkBorderLight
        : const Color(0xFFF0F2F8);
    final sectionColor = isDark
        ? AppColors.darkTextHint
        : const Color(0xFF8693B7);

    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.localeNotifier,
      builder: (context, locale, __) {
        final langDisplay = AppLocalizations.langCodeToName(locale);

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _animController,
                curve: Curves.easeOut,
              ),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              InkWell(
                                onTap: () => context.router.maybePop(),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 18,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  AppLocalizations.tr('settings'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 40),
                            ],
                          ),
                          const SizedBox(height: 28),
                          // Profile Card
                          _buildProfileCard(
                            cardColor,
                            textPrimary,
                            subtitleColor,
                          ),
                          const SizedBox(height: 28),
                          // Preferences Section
                          _sectionTitle(
                            AppLocalizations.tr('preferences'),
                            sectionColor,
                          ),
                          const SizedBox(height: 12),
                          _buildPreferencesCard(
                            cardColor,
                            textSecondary,
                            subtitleColor,
                            dividerColor,
                            langDisplay,
                            isDark,
                          ),
                          const SizedBox(height: 28),
                          // Notifications Section
                          _sectionTitle(
                            AppLocalizations.tr('notifications'),
                            sectionColor,
                          ),
                          const SizedBox(height: 12),
                          _buildNotificationsCard(
                            cardColor,
                            textSecondary,
                            subtitleColor,
                            dividerColor,
                          ),
                          const SizedBox(height: 28),
                          // Account & Safety
                          _sectionTitle(
                            AppLocalizations.tr('account_safety'),
                            sectionColor,
                          ),
                          const SizedBox(height: 12),
                          _buildAccountCard(
                            cardColor,
                            textSecondary,
                            subtitleColor,
                            dividerColor,
                          ),
                          const SizedBox(height: 28),
                          // Danger Zone
                          _sectionTitle(
                            AppLocalizations.tr('danger_zone'),
                            sectionColor,
                          ),
                          const SizedBox(height: 12),
                          _buildDangerZone(
                            cardColor,
                            textSecondary,
                            subtitleColor,
                            dividerColor,
                          ),
                          const SizedBox(height: 28),
                          // App Info
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: const Icon(
                                    Icons.favorite_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'VibePulse',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppLocalizations.tr('version'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: subtitleColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppLocalizations.tr('made_with'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: sectionColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: color,
      ),
    );
  }

  Widget _buildProfileCard(
    Color cardColor,
    Color textPrimary,
    Color subtitleColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
              image: const DecorationImage(
                image: NetworkImage('https://i.pravatar.cc/300?u=user_1'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Marcus Chen',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'marcus@vibepulse.app',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'PRO',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(
    Color cardColor,
    Color textSecondary,
    Color subtitleColor,
    Color dividerColor,
    String langDisplay,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _toggleTile(
            Icons.dark_mode_rounded,
            AppLocalizations.tr('dark_mode'),
            AppLocalizations.tr('switch_dark'),
            isDark,
            (v) {
              HapticFeedback.mediumImpact();
              AppTheme.themeModeNotifier.value = v
                  ? ThemeMode.dark
                  : ThemeMode.light;
            },
            textSecondary,
            subtitleColor,
          ),
          _tileDiv(dividerColor),
          _toggleTile(
            Icons.location_on_rounded,
            AppLocalizations.tr('location_services'),
            AppLocalizations.tr('allow_location'),
            _locationEnabled,
            (v) => setState(() => _locationEnabled = v),
            textSecondary,
            subtitleColor,
          ),
          _tileDiv(dividerColor),
          _tapTile(
            Icons.language_rounded,
            AppLocalizations.tr('language'),
            langDisplay,
            textSecondary,
            subtitleColor,
            onTap: () => _showLanguagePicker(cardColor, textSecondary),
          ),
          // _tileDiv(dividerColor),
          // _tapTile(
          //   Icons.palette_rounded,
          //   AppLocalizations.tr('appearance'),
          //   AppLocalizations.tr('system_default'),
          //   textSecondary,
          //   subtitleColor,
          //   onTap: () => _showBasicDialog(
          //     AppLocalizations.tr('appearance'),
          //     'Appearance settings are currently synced with Dark Mode toggle.',
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildNotificationsCard(
    Color cardColor,
    Color textSecondary,
    Color subtitleColor,
    Color dividerColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _toggleTile(
            Icons.notifications_active_rounded,
            AppLocalizations.tr('push_notifications'),
            AppLocalizations.tr('get_updates'),
            _pushNotifs,
            (v) => setState(() => _pushNotifs = v),
            textSecondary,
            subtitleColor,
          ),
          _tileDiv(dividerColor),
          _toggleTile(
            Icons.email_rounded,
            AppLocalizations.tr('email_notifications'),
            AppLocalizations.tr('weekly_digest'),
            _emailNotifs,
            (v) => setState(() => _emailNotifs = v),
            textSecondary,
            subtitleColor,
          ),
          _tileDiv(dividerColor),
          _toggleTile(
            Icons.notifications_rounded,
            AppLocalizations.tr('event_reminders'),
            AppLocalizations.tr('remind_events'),
            _notificationsEnabled,
            (v) => setState(() => _notificationsEnabled = v),
            textSecondary,
            subtitleColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(
    Color cardColor,
    Color textSecondary,
    Color subtitleColor,
    Color dividerColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _tapTile(
            Icons.shield_outlined,
            AppLocalizations.tr('privacy_visibility'),
            '',
            textSecondary,
            subtitleColor,
            onTap: () => _showBasicDialog(
              AppLocalizations.tr('privacy'),
              AppLocalizations.tr('privacy_desc'),
            ),
          ),
          _tileDiv(dividerColor),
          _tapTile(
            Icons.lock_outlined,
            AppLocalizations.tr('change_password'),
            '',
            textSecondary,
            subtitleColor,
            onTap: () => _showBasicDialog(
              AppLocalizations.tr('change_password'),
              AppLocalizations.tr('change_password_desc'),
            ),
          ),
          _tileDiv(dividerColor),
          _tapTile(
            Icons.account_balance_wallet_outlined,
            AppLocalizations.tr('payout_settings'),
            '',
            textSecondary,
            subtitleColor,
            onTap: () => _showBasicDialog(
              AppLocalizations.tr('payout'),
              AppLocalizations.tr('payout_desc'),
            ),
          ),
          _tileDiv(dividerColor),
          _tapTile(
            Icons.help_outline_rounded,
            AppLocalizations.tr('help_center'),
            '',
            textSecondary,
            subtitleColor,
            onTap: () => _showBasicDialog(
              AppLocalizations.tr('help_center'),
              AppLocalizations.tr('help_desc'),
            ),
          ),
          _tileDiv(dividerColor),
          _tapTile(
            Icons.description_outlined,
            AppLocalizations.tr('terms_service'),
            '',
            textSecondary,
            subtitleColor,
            onTap: () => _showBasicDialog(
              AppLocalizations.tr('terms'),
              AppLocalizations.tr('terms_desc'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(
    Color cardColor,
    Color textSecondary,
    Color subtitleColor,
    Color dividerColor,
  ) {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFEE2E8), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _iconTile(
            Icons.logout_rounded,
            AppLocalizations.tr('sign_out'),
            null,
            iconColor: const Color(0xFFE0527D),
            textColor: textSecondary,
            onTap: () => _showLogoutDialog(),
          ),
          _tileDiv(dividerColor),
          _iconTile(
            Icons.delete_forever_rounded,
            AppLocalizations.tr('delete_account'),
            AppLocalizations.tr('cannot_undone'),
            iconColor: const Color(0xFFE0527D),
            textColor: const Color(0xFFE0527D),
            subtitleColor: subtitleColor,
            onTap: () => _showDeleteDialog(),
          ),
        ],
      ),
    );
  }

  Widget _tileDiv(Color color) => Divider(indent: 68, height: 1, color: color);

  Widget _toggleTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    Color textColor,
    Color subtitleColor,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _tileIcon(icon, AppColors.primary),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: textColor,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: subtitleColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        trackColor: Colors.grey.withValues(alpha: 0.25),
      ),
    );
  }

  Widget _tapTile(
    IconData icon,
    String title,
    String? trailing,
    Color textColor,
    Color subtitleColor, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _tileIcon(icon, AppColors.primary),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: textColor,
          fontSize: 15,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(
              trailing,
              style: TextStyle(
                fontSize: 13,
                color: subtitleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA8CA)),
        ],
      ),
    );
  }

  Widget _iconTile(
    IconData icon,
    String title,
    String? subtitle, {
    Color iconColor = AppColors.primary,
    Color? textColor,
    Color? subtitleColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.only(left: 16, right: 16, top: 4),
      leading: _tileIcon(icon, iconColor),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: textColor ?? const Color(0xFF233363),
          fontSize: 15,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: subtitleColor ?? Colors.grey[500],
                fontWeight: FontWeight.w600,
              ),
            ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF9CA8CA),
      ),
    );
  }

  Widget _tileIcon(IconData icon, Color color) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  void _showLanguagePicker(Color cardColor, Color textColor) {
    final languages = [
      {'name': 'English', 'code': 'en', 'flag': '🇺🇸'},
      {'name': 'Tiếng Việt', 'code': 'vi', 'flag': '🇻🇳'},
      {'name': '日本語', 'code': 'ja', 'flag': '🇯🇵'},
      {'name': '한국어', 'code': 'ko', 'flag': '🇰🇷'},
      {'name': 'Français', 'code': 'fr', 'flag': '🇫🇷'},
    ];
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: Text(
            AppLocalizations.tr('select_language'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          actions: languages.map((lang) {
            final isCurrent = AppLocalizations.currentLocale == lang['code'];
            return CupertinoActionSheetAction(
              onPressed: () {
                HapticFeedback.selectionClick();
                AppLocalizations.setLocale(lang['code']!);
                setState(() {});
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${AppLocalizations.tr('language_changed')} ${lang['name']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.all(20),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(lang['flag']!, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Text(
                    lang['name']!,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                      color: isCurrent ? AppColors.primary : textColor,
                      fontSize: 16,
                    ),
                  ),
                  if (isCurrent) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      CupertinoIcons.checkmark_alt,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            isDestructiveAction: true,
            child: Text(
              AppLocalizations.tr('cancel'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.tr('sign_out'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(AppLocalizations.tr('sign_out_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.tr('cancel'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutRequested());
              context.router.popUntilRoot();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE0527D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              AppLocalizations.tr('sign_out'),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBasicDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(content),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              AppLocalizations.tr('ok'),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.tr('delete_account'),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFFE0527D),
          ),
        ),
        content: Text(AppLocalizations.tr('delete_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.tr('cancel'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE0527D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              AppLocalizations.tr('delete'),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
