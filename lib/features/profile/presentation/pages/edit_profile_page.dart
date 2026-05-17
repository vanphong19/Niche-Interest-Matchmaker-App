// lib/features/profile/presentation/pages/edit_profile_page.dart
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/utils/profile_state.dart';
import '../../../../core/widgets/vibe_button.dart';
import '../../../../core/widgets/vibe_text_field.dart';
import '../../../../core/widgets/snackbar_service.dart';
import '../../../../core/widgets/vibe_header.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../injection/injection_container.dart';
import '../../data/services/user_api_service.dart';

import '../../../../router/app_router.gr.dart';

@RoutePage()
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _emailCtrl;

  String? _localAvatarPath;
  Uint8List? _localAvatarBytes;
  String? _localAvatarName;
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

    // Master list of available interests to ensure "Add Interests" works even if profile list is empty
    const masterList = [
      {'name': 'Sports', 'icon': 'sports_basketball'},
      {'name': 'Music', 'icon': 'music_note'},
      {'name': 'Tech', 'icon': 'computer'},
      {'name': 'Gaming', 'icon': 'sports_esports'},
      {'name': 'Dining', 'icon': 'restaurant'},
      {'name': 'Arts', 'icon': 'palette'},
      {'name': 'Outdoors', 'icon': 'terrain'},
      {'name': 'Social', 'icon': 'people'},
      {'name': 'Photography', 'icon': 'camera_alt'},
      {'name': 'Travel', 'icon': 'flight'},
      {'name': 'Fitness', 'icon': 'fitness_center'},
      {'name': 'Movies', 'icon': 'movie'},
    ];

    // Merge user's current interests with the master list
    _allInterests = masterList.map((m) {
      // Find the user's interest safely
      final Map<String, dynamic>? userInterest = profile.interests
          .cast<Map<String, dynamic>?>()
          .firstWhere(
            (i) => i != null && i['name'] == m['name'],
            orElse: () => null,
          );

      return {
        'name': m['name'],
        'icon': m['icon'],
        'selected': userInterest?['selected'] ?? false,
      };
    }).toList();
  }

  @override
  void dispose() {
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

    String? avatarToSend = _avatarUrl;
    if (_localAvatarPath != null || _localAvatarBytes != null) {
      final userApi = sl<UserApiService>();
      final uploadedUrl = kIsWeb
          ? await userApi.uploadAvatarBytes(
              _localAvatarBytes!,
              _localAvatarName ?? 'avatar.jpg',
            )
          : await userApi.uploadAvatar(_localAvatarPath!);
      if (uploadedUrl != null) {
        avatarToSend = uploadedUrl;
      } else {
        if (!mounted) return;
        setState(() => _isSaving = false);
        VibeSnackBar.error(context, 'Failed to upload profile image.');
        return;
      }
    }

    final newProfile = ProfileState.notifier.value.copyWith(
      name: _nameCtrl.text,
      username: _usernameCtrl.text,
      bio: _bioCtrl.text,
      location: _locationCtrl.text,
      email: _emailCtrl.text,
      avatarUrl: avatarToSend,
      interests: _allInterests,
    );

    try {
      await sl<UserApiService>().updateProfile(newProfile);
      ProfileState.updateProfile(newProfile);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      VibeSnackBar.error(context, 'Failed to update profile: $e');
      return;
    }

    setState(() => _isSaving = false);

    if (!mounted) return;
    VibeSnackBar.success(context, 'Profile updated successfully!');

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) context.router.maybePop();
  }

  void _removeAvatar() {
    HapticFeedback.selectionClick();
    setState(() {
      _localAvatarPath = null;
      _localAvatarBytes = null;
      _localAvatarName = null;
      _avatarUrl = '';
    });
  }

  Future<void> _pickAvatar() async {
    HapticFeedback.selectionClick();
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Change Profile Photo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 70,
                    );
                    if (image != null) {
                      final bytes = kIsWeb ? await image.readAsBytes() : null;
                      setState(() {
                        _localAvatarPath = image.path;
                        _localAvatarBytes = bytes;
                        _localAvatarName = image.name;
                      });
                    }
                  },
                ),
                _buildPickerOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 70,
                    );
                    if (image != null) {
                      final bytes = kIsWeb ? await image.readAsBytes() : null;
                      setState(() {
                        _localAvatarPath = image.path;
                        _localAvatarBytes = bytes;
                        _localAvatarName = image.name;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
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
    final bgColor = isDark ? const Color(0xFF0E121A) : const Color(0xFFF5F7FF);

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: VibeHeader(
        title: AppLocalizations.tr('edit_profile'),
        subtitle: 'Personalize your public presence',
      ),
      body: Column(
        children: [
          SizedBox(height: 85),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 0,
                ),
                children: [
                  _buildAvatarSection(),
                  const SizedBox(height: 15),
                  _buildTextFieldsSection(isDark),
                  const SizedBox(height: 25),
                  _buildInterestsSection(isDark),
                  const SizedBox(height: 20),
                  VibeButton(
                    label: AppLocalizations.tr('save_changes'),
                    onPressed: _saveProfile,
                    isLoading: _isSaving,
                    prefixIcon: Icons.check_circle_rounded,
                    iconSize: 20,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Removed _buildPremiumHeader as it's now in Scaffold appBar

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _localAvatarPath != null
                        ? ClipOval(
                            child: kIsWeb && _localAvatarBytes != null
                                ? Image.memory(
                                    _localAvatarBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(_localAvatarPath!),
                                    fit: BoxFit.cover,
                                  ),
                          )
                        : VibeAvatar(
                            imageUrl: _avatarUrl,
                            name: _nameCtrl.text.isEmpty ? '?' : _nameCtrl.text,
                            size: 104,
                            showBorder: false,
                          ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tap to change photo',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          if (_avatarUrl.isNotEmpty || _localAvatarPath != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _removeAvatar,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  border: Border.all(
                    color: const Color(0xFFFCA5A5),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFEF4444),
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Remove Photo',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextFieldsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VibeTextField(
          label: 'Display Name',
          controller: _nameCtrl,
          hint: 'Your full name',
          prefixIcon: Icons.person_outline_rounded,
          validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
        ),
        const SizedBox(height: 16),
        VibeTextField(
          label: 'Email Address',
          controller: _emailCtrl,
          hint: 'email@example.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        VibeTextField(
          label: 'Location',
          controller: _locationCtrl,
          hint: 'Type or select your location',
          prefixIcon: Icons.location_on_outlined,
          keyboardType: TextInputType.streetAddress,
          textInputAction: TextInputAction.next,
          suffix: IconButton(
            tooltip: 'Choose on map',
            icon: const Icon(Icons.map_outlined, size: 20),
            color: AppColors.primary,
            onPressed: () async {
              HapticFeedback.selectionClick();
              final result = await context.router.push(LocationPickerRoute());
              if (result != null && result is String) {
                setState(() => _locationCtrl.text = result);
              } else if (result is Map) {
                final location =
                    (result['displayName'] ??
                            result['fullAddress'] ??
                            result['address'] ??
                            result['name'] ??
                            '')
                        .toString();
                if (location.isNotEmpty) {
                  setState(() => _locationCtrl.text = location);
                }
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        VibeTextField(
          label: 'Bio',
          controller: _bioCtrl,
          hint: 'Tell us about yourself...',
          prefixIcon: Icons.info_outline_rounded,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildInterestsSection(bool isDark) {
    final selectedCount = _allInterests
        .where((i) => i['selected'] == true)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'YOUR INTERESTS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppColors.textHint,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$selectedCount Selected',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _allInterests.map((interest) {
            final isSelected = interest['selected'] as bool;
            final name = interest['name'] as String;
            final icon = _getIcon(interest['icon'] as String);

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => interest['selected'] = !isSelected);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBgTertiary : Colors.white),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.borderLight.withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.textHint,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : AppColors.textPrimary),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
