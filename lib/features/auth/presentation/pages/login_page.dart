// lib/features/auth/presentation/pages/login_page.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:niche_interest_matchmaker_app/core/utils/profile_state.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/vibe_button.dart';
import '../../../../core/widgets/vibe_text_field.dart';

import '../../../../router/app_router.gr.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

@RoutePage()
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  // bool _isSocialLoading = false;

  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          ProfileState.init(); // Fire and forget hydration
          context.router.replaceAll([const BaseRoute()]);
        }
        // if (state is AuthError) {
        //   setState(() => _isSocialLoading = false);
        //   VibeSnackBar.error(context, state.message);
        // }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              // Background decoration
              Positioned(
                top: -100,
                right: -100,
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
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildLogo(),
                              const SizedBox(height: 40),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 400,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Welcome back',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Sign in to continue your social journey',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textHint,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    VibeTextField(
                                      label: 'Email',
                                      controller: _emailController,
                                      hint: 'Enter your email',
                                      prefixIcon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Email is required';
                                        }
                                        if (!v.contains('@')) {
                                          return 'Enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    VibeTextField(
                                      label: 'Password',
                                      controller: _passwordController,
                                      hint: 'Enter your password',
                                      prefixIcon: Icons.lock_outline_rounded,
                                      isPassword: true,
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Password is required';
                                        }
                                        if (v.length < 6) {
                                          return 'Min 6 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () => context.router.push(
                                          const ForgotPasswordRoute(),
                                        ),
                                        child: const Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    _buildLoginButton(),
                                    const SizedBox(height: 32),
                                    // _buildDivider('OR CONTINUE WITH'),
                                    // const SizedBox(height: 24),
                                    // _buildSocialButtons(),
                                    // const SizedBox(height: 40),
                                    _buildRegisterPrompt(),
                                  ],
                                ),
                              ),
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

  Widget _buildLogo() {
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
          'VibePulse',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
            fontSize: 32,
            letterSpacing: -1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return VibeButton(
          label: 'Login',
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              context.read<AuthBloc>().add(
                LoginSubmitted(
                  _emailController.text.trim(),
                  _passwordController.text,
                ),
              );
            }
          },
          isLoading: state is AuthLoading,
        );
      },
    );
  }

  // Widget _buildDivider(String label) {
  //   return Row(
  //     children: [
  //       const Expanded(child: Divider(color: AppColors.borderLight)),
  //       Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 16),
  //         child: Text(
  //           label,
  //           style: const TextStyle(
  //             fontSize: 11,
  //             fontWeight: FontWeight.w800,
  //             color: AppColors.textHint,
  //             letterSpacing: 1.0,
  //           ),
  //         ),
  //       ),
  //       const Expanded(child: Divider(color: AppColors.borderLight)),
  //     ],
  //   );
  // }

  // Widget _buildSocialButtons() {
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: _socialButton(
  //           icon: const FaIcon(
  //             FontAwesomeIcons.google,
  //             size: 18,
  //             color: Color(0xFFEA4335),
  //           ),
  //           text: 'Google',
  //           onTap: _isSocialLoading ? null : () => _handleGoogleLogin(),
  //         ),
  //       ),
  //       const SizedBox(width: 16),
  //       Expanded(
  //         child: _socialButton(
  //           icon: const FaIcon(
  //             FontAwesomeIcons.facebook,
  //             size: 18,
  //             color: Color(0xFF1877F2),
  //           ),
  //           text: 'Facebook',
  //           onTap: _isSocialLoading ? null : () => _showComingSoonDialog(),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // Future<void> _handleGoogleLogin() async {
  //   setState(() => _isSocialLoading = true);
  //   try {
  //     final data = await sl<SupabaseAuthService>().signInWithGoogle();
  //     if (!mounted || data == null) {
  //       if (mounted) setState(() => _isSocialLoading = false);
  //       return;
  //     }
  //     context.read<AuthBloc>().add(
  //       SocialLoginSubmitted(
  //         provider: data['provider'] ?? 'google',
  //         email: data['email'] ?? '',
  //         displayName: data['displayName'] ?? '',
  //         providerId: data['providerId'] ?? '',
  //       ),
  //     );
  //   } catch (e) {
  //     if (mounted) {
  //       setState(() => _isSocialLoading = false);
  //       VibeSnackBar.error(context, e.toString());
  //     }
  //   }
  // }

  // void _showComingSoonDialog() {
  //   HapticFeedback.mediumImpact();
  //   final isDark = Theme.of(context).brightness == Brightness.dark;
  //   showDialog(
  //     context: context,
  //     builder: (_) => AlertDialog(
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  //       backgroundColor: isDark ? AppColors.darkBgSecondary : Colors.white,
  //       contentPadding: const EdgeInsets.symmetric(
  //         horizontal: 28,
  //         vertical: 24,
  //       ),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Container(
  //             width: 72,
  //             height: 72,
  //             decoration: BoxDecoration(
  //               gradient: const LinearGradient(
  //                 colors: [Color(0xFF1877F2), Color(0xFF42A5F5)],
  //                 begin: Alignment.topLeft,
  //                 end: Alignment.bottomRight,
  //               ),
  //               borderRadius: BorderRadius.circular(20),
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: const Color(0xFF1877F2).withValues(alpha: 0.3),
  //                   blurRadius: 20,
  //                   offset: const Offset(0, 8),
  //                 ),
  //               ],
  //             ),
  //             child: const Center(
  //               child: FaIcon(
  //                 FontAwesomeIcons.facebook,
  //                 color: Colors.white,
  //                 size: 32,
  //               ),
  //             ),
  //           ),
  //           const SizedBox(height: 24),
  //           Text(
  //             'Coming Soon',
  //             style: TextStyle(
  //               fontSize: 22,
  //               fontWeight: FontWeight.w900,
  //               color: isDark
  //                   ? AppColors.darkTextPrimary
  //                   : AppColors.textPrimary,
  //               letterSpacing: -0.5,
  //             ),
  //           ),
  //           const SizedBox(height: 12),
  //           Text(
  //             'Facebook login is currently under development. '
  //             'Please use Google Sign-In or email to continue.',
  //             textAlign: TextAlign.center,
  //             style: TextStyle(
  //               fontSize: 14,
  //               fontWeight: FontWeight.w500,
  //               color: isDark
  //                   ? AppColors.darkTextSecondary
  //                   : AppColors.textSecondary,
  //               height: 1.5,
  //             ),
  //           ),
  //           const SizedBox(height: 8),
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               Container(
  //                 width: 6,
  //                 height: 6,
  //                 decoration: const BoxDecoration(
  //                   color: AppColors.warning,
  //                   shape: BoxShape.circle,
  //                 ),
  //               ),
  //               const SizedBox(width: 8),
  //               const Text(
  //                 'In Development',
  //                 style: TextStyle(
  //                   fontSize: 12,
  //                   fontWeight: FontWeight.w700,
  //                   color: AppColors.warning,
  //                   letterSpacing: 0.5,
  //                 ),
  //               ),
  //             ],
  //           ),
  //           const SizedBox(height: 24),
  //           VibeButton(
  //             label: 'Got it',
  //             onPressed: () => Navigator.pop(context),
  //             height: 44,
  //             fontSize: 14,
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _socialButton({
  //   required Widget icon,
  //   required String text,
  //   required VoidCallback? onTap,
  // }) {
  //   final isLoading = _isSocialLoading && text == 'Google';
  //   return InkWell(
  //     onTap: onTap,
  //     borderRadius: BorderRadius.circular(16),
  //     child: AnimatedContainer(
  //       duration: const Duration(milliseconds: 200),
  //       height: 52,
  //       decoration: BoxDecoration(
  //         borderRadius: BorderRadius.circular(16),
  //         border: Border.all(
  //           color: isLoading
  //               ? AppColors.primary.withValues(alpha: 0.4)
  //               : AppColors.borderLight,
  //           width: 1.5,
  //         ),
  //         color: isLoading
  //             ? AppColors.primary.withValues(alpha: 0.04)
  //             : Colors.transparent,
  //       ),
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           if (isLoading)
  //             const SizedBox(
  //               width: 18,
  //               height: 18,
  //               child: CircularProgressIndicator(
  //                 strokeWidth: 2,
  //                 color: AppColors.primary,
  //               ),
  //             )
  //           else
  //             icon,
  //           const SizedBox(width: 10),
  //           Text(
  //             isLoading ? 'Signing in...' : text,
  //             style: TextStyle(
  //               fontWeight: FontWeight.w700,
  //               fontSize: 14,
  //               color: isLoading ? AppColors.primary : null,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildRegisterPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'New to VibePulse? ',
          style: TextStyle(
            color: AppColors.textHint,
            fontWeight: FontWeight.w600,
          ),
        ),
        GestureDetector(
          onTap: () => context.router.push(const RegisterRoute()),
          child: const Text(
            'Create an account',
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
