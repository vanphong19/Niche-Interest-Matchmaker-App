// lib/features/auth/presentation/pages/register_page.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/theme/app_colors.dart';
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
  bool _showPassword = false;
  bool _showConfirm = false;
  bool _agreeTerms = false;

  late AnimationController _animController;
  late List<Animation<Offset>> _fieldAnimations;

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

  String get _strengthLabel {
    final s = _passwordStrength;
    if (s < 0.3) return 'Weak';
    if (s < 0.6) return 'Fair';
    return 'Strong';
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
      duration: const Duration(milliseconds: 1200),
    );

    _fieldAnimations = List.generate(6, (i) {
      final start = (i * 0.1).clamp(0.0, 0.5);
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ));
    });

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
          context.router.replaceAll([const BaseRoute()]);
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FF),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(34),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF315EEA).withValues(alpha: 0.10),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _animField(0, _buildHeader()),
                        const SizedBox(height: 20),
                        _animField(1, _buildField(
                          'FULL NAME',
                          _nameController,
                          'Alex Rivera',
                          Icons.person_outline_rounded,
                          validator: (v) => v!.isEmpty ? 'Name is required' : null,
                        )),
                        const SizedBox(height: 14),
                        _animField(2, _buildField(
                          'EMAIL ADDRESS',
                          _emailController,
                          'alex@vibepulse.com',
                          Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v!.isEmpty) return 'Email is required';
                            if (!v.contains('@')) return 'Invalid email';
                            return null;
                          },
                        )),
                        const SizedBox(height: 14),
                        _animField(3, Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('PASSWORD'),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_showPassword,
                              validator: (v) {
                                if (v!.isEmpty) return 'Password is required';
                                if (v.length < 6) return 'Min 6 characters';
                                return null;
                              },
                              decoration: _inputDecor('••••••••', Icons.lock_outline_rounded).copyWith(
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => _showPassword = !_showPassword),
                                  icon: Icon(
                                    _showPassword ? Icons.visibility : Icons.visibility_off,
                                    color: const Color(0xFF8C97B8), size: 20,
                                  ),
                                ),
                              ),
                            ),
                            if (_passwordController.text.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _passwordStrength,
                                  backgroundColor: const Color(0xFFE8ECF4),
                                  color: _strengthColor,
                                  minHeight: 4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    _strengthLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _strengthColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        )),
                        const SizedBox(height: 14),
                        _animField(4, _buildField(
                          'CONFIRM PASSWORD',
                          _confirmController,
                          '••••••••',
                          Icons.verified_user_outlined,
                          obscure: true,
                          showToggle: true,
                          validator: (v) {
                            if (v!.isEmpty) return 'Please confirm password';
                            if (v != _passwordController.text) return 'Passwords don\'t match';
                            return null;
                          },
                        )),
                        const SizedBox(height: 14),
                        _animField(5, Column(
                          children: [
                            _buildTermsCheckbox(),
                            const SizedBox(height: 14),
                            _buildRegisterButton(),
                            const SizedBox(height: 16),
                            _buildDivider('OR REGISTER WITH'),
                            const SizedBox(height: 14),
                            _buildSocialButtons(),
                            const SizedBox(height: 16),
                            _buildLoginPrompt(),
                          ],
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _animField(int index, Widget child) {
    if (index >= _fieldAnimations.length) return child;
    return SlideTransition(
      position: _fieldAnimations[index],
      child: FadeTransition(
        opacity: _animController,
        child: child,
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF7B7FFA)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.favorite_rounded, size: 22, color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text(
          'VibePulse',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        const Text(
          'Create your\naccount',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.1,
            color: Color(0xFF1B2A57),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Join us and start exploring the vibe.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF6D7AA2), fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1,
            fontWeight: FontWeight.w800,
            color: Color(0xFF95A2C2),
          ),
        ),
      );

  InputDecoration _inputDecor(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF8C97B8), size: 20),
      filled: true,
      fillColor: const Color(0xFFF0F3FF),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
    bool obscure = false,
    bool showToggle = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          obscureText: obscure && !_showConfirm,
          validator: validator,
          decoration: _inputDecor(hint, icon).copyWith(
            suffixIcon: showToggle
                ? IconButton(
                    onPressed: () => setState(() => _showConfirm = !_showConfirm),
                    icon: Icon(
                      _showConfirm ? Icons.visibility : Icons.visibility_off,
                      color: const Color(0xFF8C97B8), size: 20,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return InkWell(
      onTap: () => setState(() => _agreeTerms = !_agreeTerms),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _agreeTerms ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _agreeTerms ? AppColors.primary : const Color(0xFFBFC8E0),
                width: 2,
              ),
            ),
            child: _agreeTerms
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'I agree to the ',
                style: const TextStyle(fontSize: 13, color: Color(0xFF6D7AA2)),
                children: [
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final loading = state is AuthLoading;
        return Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: loading
                  ? null
                  : () {
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
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDivider(String label) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE3E8F5))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF9DA8C4))),
        ),
        const Expanded(child: Divider(color: Color(0xFFE3E8F5))),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: _socialBtn(const FaIcon(FontAwesomeIcons.google, size: 15, color: Color(0xFFEA4335)), 'Google'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _socialBtn(const FaIcon(FontAwesomeIcons.facebook, size: 16, color: Color(0xFF1877F2)), 'Facebook'),
        ),
      ],
    );
  }

  Widget _socialBtn(Widget icon, String label) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E8FB), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF3E4D76), fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Already have an account? ', style: TextStyle(color: Color(0xFF6F7EA6), fontWeight: FontWeight.w600)),
        GestureDetector(
          onTap: () => context.router.maybePop(),
          child: const Text('Log in', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}
