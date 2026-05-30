import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:niche_interest_matchmaker_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:niche_interest_matchmaker_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:niche_interest_matchmaker_app/core/theme/app_colors.dart';
import 'package:niche_interest_matchmaker_app/core/theme/app_text_styles.dart';
import 'package:niche_interest_matchmaker_app/core/utils/profile_state.dart';
import 'package:niche_interest_matchmaker_app/injection/injection_container.dart';
import 'package:niche_interest_matchmaker_app/router/app_router.gr.dart';
import 'package:niche_interest_matchmaker_app/features/event/presentation/bloc/event_bloc.dart';
import 'package:niche_interest_matchmaker_app/core/services/signalr_service.dart';

@RoutePage()
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  double _loadProgress = 0.0;
  String _loadingText = "Initializing VibePulse...";

  @override
  void initState() {
    super.initState();
    _startPreLoading();
  }

  Future<void> _startPreLoading() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token');

    if (token == null || token.isEmpty) {
      // Check if we just returned from a Web Supabase OAuth redirect
      final supabaseSession = Supabase.instance.client.auth.currentSession;
      if (supabaseSession != null) {
        setState(() {
          _loadProgress = 0.5;
          _loadingText = "Authenticating with server...";
        });
        final metadata = supabaseSession.user.userMetadata ?? {};
        if (mounted) {
          context.read<AuthBloc>().add(
            SocialLoginSubmitted(
              provider: 'google',
              email: supabaseSession.user.email ?? '',
              displayName:
                  metadata['full_name']?.toString() ??
                  metadata['name']?.toString() ??
                  '',
              providerId: supabaseSession.user.id,
            ),
          );
        }
        return; // Let app.dart BlocListener handle the navigation
      }

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) AutoRouter.of(context).replaceAll([const LoginRoute()]);
      return;
    }

    // ─── Parallel Pre-fetching ───
    final startTime = DateTime.now();

    try {
      setState(() {
        _loadProgress = 0.1;
        _loadingText = "Syncing your profile...";
      });
      await ProfileState.init(); // Hydrate ProfileState

      setState(() {
        _loadProgress = 0.4;
        _loadingText = "Curating your vibe feed...";
      });
      final eventBloc = sl<EventBloc>();
      eventBloc.add(LoadEvents()); // This loads both feed AND my events

      setState(() {
        _loadProgress = 0.7;
        _loadingText = "Establishing real-time link...";
      });
      // SignalR is already started in main, but we ensure it's init
      await sl<SignalRService>().init();

      setState(() {
        _loadProgress = 0.9;
        _loadingText = "Setting the mood...";
      });

      // Ensure at least 2.5 seconds for branding effect
      final elapsed = DateTime.now().difference(startTime);
      final minDuration = const Duration(milliseconds: 2500);
      if (elapsed < minDuration) {
        await Future.delayed(minDuration - elapsed);
      }

      setState(() {
        _loadProgress = 1.0;
        _loadingText = "Ready to elevate.";
      });

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) AutoRouter.of(context).replaceAll([const BaseRoute()]);
    } catch (e) {
      debugPrint('Pre-loading error: $e');
      if (mounted) AutoRouter.of(context).replaceAll([const BaseRoute()]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A), // Deep Obsidian
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ─── Luxury Mesh Background ───
          Positioned(
            top: -100,
            right: -100,
            child:
                Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.25),
                            AppColors.primary.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .move(
                      begin: const Offset(0, 0),
                      end: const Offset(-50, 50),
                      duration: const Duration(seconds: 8),
                      curve: Curves.easeInOut,
                    ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child:
                Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF7B7FFA).withValues(alpha: 0.2),
                            const Color(0xFF7B7FFA).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .move(
                      begin: const Offset(0, 0),
                      end: const Offset(40, -40),
                      duration: const Duration(seconds: 10),
                      curve: Curves.easeInOut,
                    ),
          ),

          // ─── Main Content ───
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // Logo Container with Glassmorphism
                Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.white, Color(0xFFB4B6FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: const Icon(
                            Icons.favorite_rounded,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .scale(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: const Duration(milliseconds: 800))
                    .shimmer(
                      delay: const Duration(seconds: 1),
                      duration: const Duration(seconds: 2),
                    ),

                const SizedBox(height: 40),

                Text(
                      'VibePulse',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: Colors.white,
                        fontSize: 44,
                        letterSpacing: -2,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                    .animate()
                    .fadeIn(
                      delay: const Duration(milliseconds: 400),
                      duration: const Duration(milliseconds: 600),
                    )
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 12),

                Text(
                  'Elevate your social frequency',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ).animate().fadeIn(
                  delay: const Duration(milliseconds: 700),
                  duration: const Duration(milliseconds: 600),
                ),

                const Spacer(flex: 2),

                // Modern Progress Indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          children: [
                            Container(
                              height: 3,
                              width: double.infinity,
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              height: 3,
                              width:
                                  MediaQuery.of(context).size.width *
                                  0.7 *
                                  _loadProgress,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    Color(0xFF7B7FFA),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _loadingText,
                          key: ValueKey(_loadingText),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: const Duration(seconds: 1)),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
