// lib/features/auth/presentation/pages/register_page.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:niche_interest_matchmaker_app/core/utils/profile_state.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/vibe_button.dart';
import '../../../../core/widgets/vibe_text_field.dart';
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
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(p)) s += 0.2;
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
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        body: Stack(
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
                                if (v == null || v.isEmpty)
                                  return 'Email is required';
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
                                if (v == null || v.isEmpty)
                                  return 'Password is required';
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
                                if (v == null || v.isEmpty)
                                  return 'Please confirm password';
                                if (v != _passwordController.text)
                                  return 'Passwords don\'t match';
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
            InkWell(
              onTap: () => setState(() => _agreeTerms = !_agreeTerms),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _agreeTerms ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _agreeTerms
                        ? AppColors.primary
                        : AppColors.borderLight,
                    width: 2,
                  ),
                ),
                child: _agreeTerms
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please accept terms')),
              );
              return;
            }
            if (_formKey.currentState!.validate()) {
              context.read<AuthBloc>().add(
                RegisterSubmitted(
                  _nameController.text.trim(),
                  _emailController.text.trim(),
                  _passwordController.text,
                ),
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
          ),
        ),
      ],
    );
  }

  Widget _socialBtn(Widget icon, String label) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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
}
