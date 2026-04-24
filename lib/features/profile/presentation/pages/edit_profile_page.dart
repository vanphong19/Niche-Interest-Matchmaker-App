// lib/features/profile/presentation/pages/edit_profile_page.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/utils/profile_state.dart';

@RoutePage()
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _emailCtrl;

  late String _avatarUrl;
  late List<Map<String, dynamic>> _allInterests;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ProfileState.notifier.value;
    _nameCtrl = TextEditingController(text: profile.name);
    _usernameCtrl = TextEditingController(text: profile.username);
    _bioCtrl = TextEditingController(text: profile.bio);
    _locationCtrl = TextEditingController(text: profile.location);
    _emailCtrl = TextEditingController(text: profile.email);
    _avatarUrl = profile.avatarUrl;
    _allInterests = profile.interests
        .map((i) => Map<String, dynamic>.from(i))
        .toList();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    ProfileState.updateProfile(
      ProfileState.notifier.value.copyWith(
        name: _nameCtrl.text,
        username: _usernameCtrl.text,
        bio: _bioCtrl.text,
        location: _locationCtrl.text,
        email: _emailCtrl.text,
        avatarUrl: _avatarUrl,
        interests: _allInterests,
      ),
    );
    setState(() => _isSaving = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              'Profile updated!',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) context.router.maybePop();
  }

  void _pickAvatar() {
    HapticFeedback.selectionClick();
    setState(() {
      _avatarUrl =
          'https://i.pravatar.cc/300?u=${DateTime.now().millisecondsSinceEpoch}';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.photo_camera_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Avatar updated!',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static IconData _getIcon(String name) {
    switch (name) {
      case 'sports_basketball':
        return Icons.sports_basketball;
      case 'music_note':
        return Icons.music_note;
      case 'computer':
        return Icons.computer;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'restaurant':
        return Icons.restaurant;
      case 'palette':
        return Icons.palette;
      case 'terrain':
        return Icons.terrain;
      case 'people':
        return Icons.people;
      case 'camera_alt':
        return Icons.camera_alt;
      case 'flight':
        return Icons.flight;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'movie':
        return Icons.movie;
      default:
        return Icons.local_activity;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.darkBgPrimary : const Color(0xFFF5F7FF);
    final cardColor = isDark ? AppColors.darkCardBackground : Colors.white;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF1B2A57);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: _animController,
            curve: Curves.easeOut,
          ),
          child: Column(
            children: [
              // ── Header ──
              _buildHeader(cardColor, textPrimary, isDark),
              // ── Form ──
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildAvatarSection(cardColor),
                      const SizedBox(height: 28),
                      _buildInfoSection(textPrimary, isDark),
                      const SizedBox(height: 28),
                      _buildInterestsSection(textPrimary, isDark),
                      const SizedBox(height: 32),
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color cardColor, Color textPrimary, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.router.maybePop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: textPrimary),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            AppLocalizations.tr('edit_profile'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(Color cardColor) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              children: [
                Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: ClipOval(
                      child: Image.network(
                        _avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (e, s, t) => Container(
                          color: AppColors.bgSecondary,
                          child: const Icon(Icons.person_rounded,
                              color: AppColors.textHint, size: 40),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.tr('tap_change_photo'),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(Color textPrimary, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Personal Info', isDark),
        const SizedBox(height: 14),
        _FieldGroup(
          isDark: isDark,
          children: [
            _buildTextField(
              controller: _nameCtrl,
              hint: 'Display name',
              icon: Icons.person_rounded,
              textPrimary: textPrimary,
              isDark: isDark,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Name required' : null,
            ),
            _divider(isDark),
            _buildTextField(
              controller: _usernameCtrl,
              hint: 'Username',
              icon: Icons.alternate_email_rounded,
              prefix: '@',
              textPrimary: textPrimary,
              isDark: isDark,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Username required' : null,
            ),
            _divider(isDark),
            _buildTextField(
              controller: _emailCtrl,
              hint: 'Email address',
              icon: Icons.email_rounded,
              textPrimary: textPrimary,
              isDark: isDark,
              keyboard: TextInputType.emailAddress,
            ),
            _divider(isDark),
            _buildTextField(
              controller: _locationCtrl,
              hint: 'City / Location',
              icon: Icons.location_on_rounded,
              textPrimary: textPrimary,
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionTitle('Bio', isDark),
        const SizedBox(height: 10),
        _FieldGroup(
          isDark: isDark,
          children: [
            _buildTextField(
              controller: _bioCtrl,
              hint: 'Tell people about yourself…',
              icon: Icons.chat_bubble_outline_rounded,
              textPrimary: textPrimary,
              isDark: isDark,
              maxLines: 3,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color textPrimary,
    required bool isDark,
    String? prefix,
    int maxLines = 1,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      validator: validator,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: textPrimary,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.textHint,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 6, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              if (prefix != null) ...[
                const SizedBox(width: 8),
                Text(
                  prefix,
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ],
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 44),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark
          ? Colors.white.withValues(alpha: 0.07)
          : AppColors.borderLight,
    );
  }

  Widget _buildInterestsSection(Color textPrimary, bool isDark) {
    final selectedCount =
        _allInterests.where((i) => i['selected'] == true).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SectionTitle('Your Interests', isDark),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$selectedCount selected',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _allInterests.map((interest) {
            final isSelected = interest['selected'] as bool;
            final name = interest['name'] as String;
            final color = AppColors.getCategoryColor(name);
            final icon = _getIcon(interest['icon'] as String);

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  interest['selected'] = !isSelected;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSelected
                        ? isDark
                            ? [
                                color.withValues(alpha: 0.28),
                                const Color(0xFF1A2233),
                              ]
                            : [
                                color.withValues(alpha: 0.15),
                                Colors.white,
                              ]
                        : [
                            isDark
                                ? AppColors.darkBgTertiary
                                : AppColors.bgSecondary,
                            isDark
                                ? AppColors.darkBgTertiary
                                : AppColors.bgSecondary,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? color.withValues(alpha: 0.5)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : AppColors.borderLight),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.16)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.white),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        icon,
                        size: 15,
                        color: isSelected ? color : AppColors.textHint,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isSelected
                            ? (isDark
                                ? AppColors.darkTextPrimary
                                : color.withValues(alpha: 0.9))
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary),
                        fontSize: 13,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 7),
                      Icon(Icons.check_circle_rounded,
                          size: 14, color: color),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 10,
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_rounded, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    AppLocalizations.tr('save_changes'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, this.isDark);
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.4,
        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF8693B7),
      ),
    );
  }
}

class _FieldGroup extends StatelessWidget {
  const _FieldGroup({required this.children, required this.isDark});
  final List<Widget> children;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(children: children),
      ),
    );
  }
}
