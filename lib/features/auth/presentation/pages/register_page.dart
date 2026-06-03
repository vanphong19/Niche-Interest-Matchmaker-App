// lib/features/auth/presentation/pages/register_page.dart
import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:niche_interest_matchmaker_app/core/utils/profile_state.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/snackbar_service.dart';
import '../../../../core/widgets/vibe_button.dart';
import '../../../../core/widgets/vibe_text_field.dart';
import '../../../../features/auth/data/services/supabase_auth_service.dart';
import '../../../../injection/injection_container.dart';
import '../../../../router/app_router.gr.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

@RoutePage()
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _agreeTerms = false;
  bool _isSocialLoading = false;
  bool _isOtpDialogShowing = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  double get _passwordStrength {
    final p = _passwordController.text;
    if (p.isEmpty) return 0;
    double s = 0;
    if (p.length >= 6) s += 0.25;
    if (p.length >= 8) s += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(p)) s += 0.2;
    if (RegExp(r'[0-9]').hasMatch(p)) s += 0.2;
    if (RegExp(r'[!@#\$%^\&*(),.?":{}|<>]').hasMatch(p)) s += 0.2;
    return s.clamp(0.0, 1.0);
  }

  Color get _strengthColor {
    final s = _passwordStrength;
    if (s < 0.3) return AppColors.error;
    if (s < 0.6) return AppColors.warning;
    return AppColors.success;
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          ProfileState.init();
          context.router.replaceAll([const BaseRoute()]);
        }
        if (state is AuthOtpSentSuccess) {
          if (!_isOtpDialogShowing) {
            _showOtpDialog(context, state.email);
          } else {
            VibeSnackBar.success(
              context,
              'Đã gửi lại mã xác thực OTP thành công!',
            );
          }
        }
        if (state is AuthError) {
          setState(() => _isSocialLoading = false);
          VibeSnackBar.error(context, state.message);
        }
      },
      child: Scaffold(
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              Positioned(
                bottom: -100,
                left: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Form(
                        key: _formKey,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Column(
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 40),
                              VibeTextField(
                                label: 'Full Name',
                                controller: _nameController,
                                hint: 'Alex Rivera',
                                prefixIcon: Icons.person_outline_rounded,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Name is required'
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              VibeTextField(
                                label: 'Email Address',
                                controller: _emailController,
                                hint: 'alex@vibepulse.com',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Email is required';
                                  }
                                  if (!v.contains('@')) return 'Invalid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              VibeTextField(
                                label: 'Password',
                                controller: _passwordController,
                                hint: '••••••••',
                                prefixIcon: Icons.lock_outline_rounded,
                                isPassword: true,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (v.length < 6) return 'Min 6 characters';
                                  return null;
                                },
                              ),
                              if (_passwordController.text.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _buildPasswordStrength(),
                              ],
                              const SizedBox(height: 20),
                              VibeTextField(
                                label: 'Confirm Password',
                                controller: _confirmController,
                                hint: '••••••••',
                                prefixIcon: Icons.verified_user_outlined,
                                isPassword: true,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Please confirm password';
                                  }
                                  if (v != _passwordController.text) {
                                    return 'Passwords don\'t match';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              _buildTermsCheckbox(),
                              const SizedBox(height: 32),
                              _buildRegisterButton(),
                              const SizedBox(height: 32),
                              _buildDivider('OR REGISTER WITH'),
                              const SizedBox(height: 24),
                              _buildSocialButtons(),
                              const SizedBox(height: 40),
                              _buildLoginPrompt(),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildPasswordStrength() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _passwordStrength,
            backgroundColor: AppColors.borderLight,
            color: _strengthColor,
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.favorite_rounded,
            size: 32,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Join VibePulse',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Start exploring the social frontier',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textHint,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return GestureDetector(
      onTap: () => setState(() => _agreeTerms = !_agreeTerms),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _agreeTerms ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _agreeTerms
                      ? AppColors.primary
                      : AppColors.borderLight,
                  width: 1.2,
                ),
              ),
              child: _agreeTerms
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'I agree to the Terms & Privacy Policy',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return VibeButton(
          label: 'Create Account',
          onPressed: () {
            if (!_agreeTerms) {
              VibeSnackBar.warning(context, 'Please accept terms');
              return;
            }
            if (_formKey.currentState!.validate()) {
              context.read<AuthBloc>().add(
                SendOtpRequested(_emailController.text.trim()),
              );
            }
          },
          isLoading: state is AuthLoading,
          suffixIcon: Icons.arrow_forward_rounded,
        );
      },
    );
  }

  Widget _buildDivider(String label) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.borderLight)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textHint,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.borderLight)),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: _socialBtn(
            const FaIcon(
              FontAwesomeIcons.google,
              size: 18,
              color: Color(0xFFEA4335),
            ),
            'Google',
            onTap: _isSocialLoading ? null : () => _handleGoogleLogin(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _socialBtn(
            const FaIcon(
              FontAwesomeIcons.facebook,
              size: 18,
              color: Color(0xFF1877F2),
            ),
            'Facebook',
            onTap: _isSocialLoading ? null : () => _showComingSoonDialog(),
          ),
        ),
      ],
    );
  }

  Widget _socialBtn(Widget icon, String label, {VoidCallback? onTap}) {
    final isLoading = _isSocialLoading && label == 'Google';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLoading
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.borderLight,
            width: 1.5,
          ),
          color: isLoading
              ? AppColors.primary.withValues(alpha: 0.04)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            else
              icon,
            const SizedBox(width: 10),
            Text(
              isLoading ? 'Signing in...' : label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isLoading ? AppColors.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isSocialLoading = true);
    try {
      final data = await sl<SupabaseAuthService>().signInWithGoogle();
      if (!mounted || data == null) {
        if (mounted) setState(() => _isSocialLoading = false);
        return;
      }
      context.read<AuthBloc>().add(
        SocialLoginSubmitted(
          provider: data['provider'] ?? 'google',
          email: data['email'] ?? '',
          displayName: data['displayName'] ?? '',
          providerId: data['providerId'] ?? '',
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSocialLoading = false);
        VibeFeedback.apiError(context, e);
      }
    }
  }

  void _showComingSoonDialog() {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? AppColors.darkBgSecondary : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 28,
          vertical: 24,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1877F2), Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1877F2).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: FaIcon(
                  FontAwesomeIcons.facebook,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Facebook login is currently under development. '
              'Please use Google Sign-In or email to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'In Development',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            VibeButton(
              label: 'Got it',
              onPressed: () => Navigator.pop(context),
              height: 44,
              fontSize: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(
            color: AppColors.textHint,
            fontWeight: FontWeight.w600,
          ),
        ),
        GestureDetector(
          onTap: () => context.router.maybePop(),
          child: const Text(
            'Log in',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  void _showOtpDialog(BuildContext context, String email) {
    setState(() => _isOtpDialogShowing = true);
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _OtpVerificationDialog(
        email: email,
        name: _nameController.text.trim(),
        password: _passwordController.text,
      ),
    ).then((_) {
      setState(() => _isOtpDialogShowing = false);
    });
  }
}

class _OtpVerificationDialog extends StatefulWidget {
  final String email;
  final String name;
  final String password;

  const _OtpVerificationDialog({
    required this.email,
    required this.name,
    required this.password,
  });

  @override
  State<_OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<_OtpVerificationDialog> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _countdown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    setState(() => _countdown = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? AppColors.darkBgSecondary : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFE6EEFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_unread_rounded,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Xác thực Email',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Chúng tôi đã gửi mã xác thực gồm 6 chữ số đến email\n${widget.email}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: 10,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '000000',
                hintStyle: const TextStyle(
                  color: Colors.grey,
                  letterSpacing: 10,
                ),
                filled: true,
                fillColor: isDark
                    ? AppColors.darkBgTertiary
                    : AppColors.bgSecondary,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.borderLight,
                    width: 1.2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.error,
                    width: 1.2,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.error,
                    width: 1.2,
                  ),
                ),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Vui lòng nhập mã OTP';
                if (v.length < 6) return 'Mã OTP phải gồm 6 chữ số';
                return null;
              },
            ),
            const SizedBox(height: 20),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final loading = state is AuthLoading;
                return VibeButton(
                  label: 'Xác nhận & Đăng ký',
                  isLoading: loading,
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      context.read<AuthBloc>().add(
                        RegisterSubmitted(
                          widget.name,
                          widget.email,
                          widget.password,
                          _otpController.text.trim(),
                        ),
                      );
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Hủy',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                if (_countdown > 0)
                  Text(
                    'Gửi lại sau ${_countdown}s',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  )
                else
                  TextButton(
                    onPressed: () {
                      context.read<AuthBloc>().add(
                        SendOtpRequested(widget.email),
                      );
                      _startCountdown();
                    },
                    child: const Text(
                      'Gửi lại mã',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
