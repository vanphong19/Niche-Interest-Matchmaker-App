// lib/features/auth/presentation/pages/forgot_password_page.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/snackbar_service.dart';
import '../../../../core/widgets/vibe_button.dart';
import '../../../../core/widgets/vibe_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

@RoutePage()
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  bool _submitted = false;
  bool _resetSuccess = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthForgotPasswordSuccess) {
          setState(() => _submitted = true);
        }
        if (state is AuthResetPasswordSuccess) {
          setState(() {
            _resetSuccess = true;
            _submitted = true;
          });
          VibeSnackBar.success(context, state.message);
        }
        if (state is AuthError) {
          VibeSnackBar.error(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            Positioned(
              top: -80,
              right: -100,
              child: Container(
                width: 360,
                height: 420,
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Color(0x44CED9FF), Color(0x00FFFFFF)],
                    stops: [0.15, 1],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: _submitted ? _buildSuccess() : _buildForm(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Lock icon with glow
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFE6EEFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Forgot Password?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              height: 1.0,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1B2A57),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No worries! Enter your email below and we\'ll send you a link to reset your vibes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6D7AA2),
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColors.borderLight.withValues(alpha: 0.8),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VibeTextField(
                    label: 'Email Address',
                    controller: _emailController,
                    hint: 'alex.rivera@vibepulse.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email is required';
                      if (!v.contains('@')) return 'Invalid email format';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final loading = state is AuthLoading;
                      return VibeButton(
                        label: 'Reset Password',
                        isLoading: loading,
                        suffixIcon: Icons.arrow_forward_rounded,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            context.read<AuthBloc>().add(
                              ForgotPasswordSubmitted(
                                _emailController.text.trim(),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => context.router.maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    label: const Text(
                      'Back to login',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'VIBEPULSE IDENTITY SYSTEM © 2026',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              color: Color(0xFFA1ABCA),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    if (_resetSuccess) {
      return Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 56,
                color: AppColors.success,
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Đặt lại thành công!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1B2A57),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Mật khẩu của ${_emailController.text} đã được thay đổi.\nBạn có thể đăng nhập ngay bây giờ.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6D7AA2),
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            child: OutlinedButton(
              onPressed: () => context.router.maybePop(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Back to Login',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      );
    }

    // Otherwise, show the reset password code input and new password form!
    return Form(
      key: _resetFormKey,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFE6EEFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_open_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Đặt mật khẩu mới',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              height: 1.0,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1B2A57),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Nhập mã xác thực đã được gửi đến ${_emailController.text} và thiết lập mật khẩu mới.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6D7AA2),
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColors.borderLight.withValues(alpha: 0.8),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VibeTextField(
                    label: 'Mã xác thực (OTP)',
                    controller: _codeController,
                    hint: '123456',
                    prefixIcon: Icons.pin_rounded,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Vui lòng nhập mã OTP';
                      if (v.length < 6) return 'Mã OTP gồm 6 chữ số';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  VibeTextField(
                    label: 'Mật khẩu mới',
                    controller: _newPasswordController,
                    isPassword: true,
                    prefixIcon: Icons.lock_rounded,
                    hint: '••••••••',
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu mới';
                      if (v.length < 6) return 'Mật khẩu phải từ 6 ký tự';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  VibeTextField(
                    label: 'Xác nhận mật khẩu mới',
                    controller: _confirmPasswordController,
                    isPassword: true,
                    prefixIcon: Icons.lock_outline_rounded,
                    hint: '••••••••',
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                      if (v != _newPasswordController.text) return 'Mật khẩu xác nhận không khớp';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final loading = state is AuthLoading;
                      return VibeButton(
                        label: 'Đặt lại mật khẩu',
                        isLoading: loading,
                        suffixIcon: Icons.arrow_forward_rounded,
                        onPressed: () {
                          if (_resetFormKey.currentState!.validate()) {
                            context.read<AuthBloc>().add(
                              ResetPasswordSubmitted(
                                email: _emailController.text.trim(),
                                code: _codeController.text.trim(),
                                newPassword: _newPasswordController.text,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _submitted = false;
                        _codeController.clear();
                        _newPasswordController.clear();
                        _confirmPasswordController.clear();
                      });
                    },
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    label: const Text(
                      'Quay lại nhập Email',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
