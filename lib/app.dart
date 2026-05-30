// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/app_localizations.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'injection/injection_container.dart';
import 'core/widgets/no_scroll_glow_behavior.dart';
import 'router/app_router.dart';
import 'router/app_router.gr.dart';

class VibeApp extends StatefulWidget {
  const VibeApp({super.key});

  @override
  State<VibeApp> createState() => _VibeAppState();
}

class _VibeAppState extends State<VibeApp> {
  final _appRouter = AppRouterProvider.instance;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider<AuthBloc>(create: (_) => sl<AuthBloc>())],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            _appRouter.replaceAll([const BaseRoute()]);
          } else if (state is AuthUnauthenticated) {
            _appRouter.replaceAll([const LoginRoute()]);
          }
        },
        child: ValueListenableBuilder<String>(
          valueListenable: AppLocalizations.localeNotifier,
          builder: (context, localeStr, _) {
            return ValueListenableBuilder<ThemeMode>(
              valueListenable: AppTheme.themeModeNotifier,
              builder: (context, themeMode, _) {
                return MaterialApp.router(
                  title: 'VibePulse',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: themeMode,
                  locale: Locale(localeStr),
                  scrollBehavior: NoScrollGlowBehavior(),
                  builder: (context, child) {
                    return GestureDetector(
                      onTap: () {
                        final currentFocus = FocusScope.of(context);
                        if (!currentFocus.hasPrimaryFocus &&
                            currentFocus.focusedChild != null) {
                          FocusManager.instance.primaryFocus?.unfocus();
                        }
                      },
                      child: child,
                    );
                  },
                  routerConfig: _appRouter.config(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
