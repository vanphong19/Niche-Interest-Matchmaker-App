import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/widgets/vibe_button.dart';
import '../../../../core/widgets/vibe_text_field.dart';
import '../../../../core/widgets/vibe_header.dart';
import '../../../../core/widgets/snackbar_service.dart';
import '../../../../injection/injection_container.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

@RoutePage()
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_oldPasswordCtrl.text.isEmpty || _newPasswordCtrl.text.isEmpty) {
      _showSnackBar('Please fill all fields');
      return;
    }

    if (_newPasswordCtrl.text != _confirmPasswordCtrl.text) {
      _showSnackBar('New passwords do not match');
      return;
    }

    if (_newPasswordCtrl.text.length < 6) {
      _showSnackBar('Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      await sl<AuthRepository>().changePassword(
        _oldPasswordCtrl.text,
        _newPasswordCtrl.text,
      );
      if (mounted) {
        _showSnackBar('Password changed successfully', isError: false);
        context.router.pop();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (isError) {
      VibeSnackBar.error(context, message);
    } else {
      VibeSnackBar.success(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBgPrimary : const Color(0xFFF5F7FF);
    final cardColor = isDark ? AppColors.darkCardBackground : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: VibeHeader(
        title: AppLocalizations.tr('change_password'),
        subtitle: 'Secure your account with a strong password',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    VibeTextField(
                      controller: _oldPasswordCtrl,
                      label: 'Current Password',
                      isPassword: true,
                      prefixIcon: Icons.lock_outline_rounded,
                      hint: 'Enter current password',
                    ),
                    const SizedBox(height: 20),
                    VibeTextField(
                      controller: _newPasswordCtrl,
                      label: 'New Password',
                      isPassword: true,
                      prefixIcon: Icons.lock_outline_rounded,
                      hint: 'Enter new password',
                    ),
                    const SizedBox(height: 20),
                    VibeTextField(
                      controller: _confirmPasswordCtrl,
                      label: 'Confirm New Password',
                      isPassword: true,
                      prefixIcon: Icons.verified_user_outlined,
                      hint: 'Confirm new password',
                    ),
                    const SizedBox(height: 32),
                    VibeButton(
                      label: 'Update Password',
                      onPressed: _isLoading ? null : _handleSubmit,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Password Requirements',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _requirementItem('Minimum 6 characters'),
                    _requirementItem('Include letters and numbers'),
                    _requirementItem('Avoid using your name or email'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _requirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
