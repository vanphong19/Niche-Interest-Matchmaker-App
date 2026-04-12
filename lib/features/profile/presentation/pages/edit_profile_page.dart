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
    
    // Deep copy interests to avoid modifying the global state directly until saved
    _allInterests = profile.interests.map((i) => Map<String, dynamic>.from(i)).toList();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animController.forward();
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

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    // Simulate save
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    
    final newProfile = ProfileState.notifier.value.copyWith(
      name: _nameCtrl.text,
      username: _usernameCtrl.text,
      bio: _bioCtrl.text,
      location: _locationCtrl.text,
      email: _emailCtrl.text,
      avatarUrl: _avatarUrl,
      interests: _allInterests,
    );
    ProfileState.updateProfile(newProfile);

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(AppLocalizations.tr('profile_updated'),
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: Colors.white)),
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
    // Simulate avatar picking with random avatar
    HapticFeedback.selectionClick();
    setState(() {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _avatarUrl = 'https://i.pravatar.cc/300?u=$timestamp';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.photo_camera_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(AppLocalizations.tr('avatar_updated'),
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: Colors.white)),
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

  IconData _getIcon(String name) {
    switch (name) {
      case 'sports_basketball': return Icons.sports_basketball;
      case 'music_note': return Icons.music_note;
      case 'computer': return Icons.computer;
      case 'sports_esports': return Icons.sports_esports;
      case 'restaurant': return Icons.restaurant;
      case 'palette': return Icons.palette;
      case 'terrain': return Icons.terrain;
      case 'people': return Icons.people;
      case 'camera_alt': return Icons.camera_alt;
      case 'flight': return Icons.flight;
      case 'fitness_center': return Icons.fitness_center;
      case 'movie': return Icons.movie;
      default: return Icons.local_activity;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBgPrimary : const Color(0xFFF5F7FF);
    final cardColor = isDark ? AppColors.darkCardBackground : Colors.white;
    final textPrimary = isDark ? AppColors.darkTextPrimary : const Color(0xFF1B2A57);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: CurvedAnimation(
              parent: _animController, curve: Curves.easeOut),
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
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
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18, color: textPrimary),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        AppLocalizations.tr('edit_profile'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textPrimary),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              // Form
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      // Avatar Section
                      _buildAvatarSection(cardColor),
                      const SizedBox(height: 28),
                      // Personal Info
                      _buildSectionLabel(AppLocalizations.tr('display_name').toUpperCase()),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _nameCtrl,
                        hint: AppLocalizations.tr('your_display_name'),
                        icon: Icons.person_rounded,
                        cardColor: cardColor,
                        textColor: textPrimary,
                        validator: (v) =>
                            v == null || v.isEmpty ? AppLocalizations.tr('name_required') : null,
                      ),
                      const SizedBox(height: 16),
                      _buildSectionLabel(AppLocalizations.tr('username').toUpperCase()),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _usernameCtrl,
                        hint: AppLocalizations.tr('your_username'),
                        icon: Icons.alternate_email_rounded,
                        prefix: '@',
                        cardColor: cardColor,
                        textColor: textPrimary,
                        validator: (v) =>
                            v == null || v.isEmpty ? AppLocalizations.tr('username_required') : null,
                      ),
                      const SizedBox(height: 16),
                      _buildSectionLabel(AppLocalizations.tr('email')),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _emailCtrl,
                        hint: AppLocalizations.tr('your_email'),
                        icon: Icons.email_rounded,
                        cardColor: cardColor,
                        textColor: textPrimary,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _buildSectionLabel(AppLocalizations.tr('bio').toUpperCase()),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _bioCtrl,
                        hint: AppLocalizations.tr('tell_people'),
                        icon: Icons.chat_bubble_rounded,
                        maxLines: 3,
                        cardColor: cardColor,
                        textColor: textPrimary,
                      ),
                      const SizedBox(height: 16),
                      _buildSectionLabel(AppLocalizations.tr('location').toUpperCase()),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _locationCtrl,
                        hint: AppLocalizations.tr('your_city'),
                        icon: Icons.location_on_rounded,
                        cardColor: cardColor,
                        textColor: textPrimary,
                      ),
                      const SizedBox(height: 32),
                      // Interests Section
                      _buildSectionLabel(AppLocalizations.tr('select_interests').toUpperCase()),
                      const SizedBox(height: 16),
                      _buildInterestsGrid(cardColor, textPrimary, isDark),
                      const SizedBox(height: 40),
                      // Save Button
                      _buildSaveButton(),
                      const SizedBox(height: 20),
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

  Widget _buildAvatarSection(Color cardColor) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.primary, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color:
                            AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                    image: DecorationImage(
                      image: NetworkImage(_avatarUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: cardColor, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(AppLocalizations.tr('tap_change_photo'),
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: Color(0xFF8693B7),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color cardColor,
    required Color textColor,
    String? prefix,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
          fontWeight: FontWeight.w600, color: textColor, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: AppColors.textHint, fontWeight: FontWeight.w500),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              if (prefix != null) ...[
                const SizedBox(width: 8),
                Text(prefix,
                    style: const TextStyle(
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ],
            ],
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: cardColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
      ),
    );
  }

  Widget _buildInterestsGrid(Color cardColor, Color textColor, bool isDark) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _allInterests.map((interest) {
        final isSelected = interest['selected'] as bool;
        final color = AppColors.getCategoryColor(interest['name']);
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              interest['selected'] = !isSelected;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.15),
                        color.withValues(alpha: 0.08),
                      ],
                    )
                  : null,
              color: isSelected ? null : (isDark ? AppColors.darkBgTertiary : AppColors.bgTertiary),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? color.withValues(alpha: 0.5)
                    : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getIcon(interest['icon'] as String),
                  size: 18,
                  color: isSelected ? color : AppColors.textHint,
                ),
                const SizedBox(width: 8),
                Text(
                  interest['name'],
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? color : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    fontSize: 14,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.check_circle_rounded,
                      size: 16, color: color),
                ],
              ],
            ),
          ),
        );
      }).toList(),
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
          elevation: 8,
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 3, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_rounded, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    AppLocalizations.tr('save_changes'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0.5),
                  ),
                ],
              ),
      ),
    );
  }
}
