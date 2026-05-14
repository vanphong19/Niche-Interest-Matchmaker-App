// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_localizations.dart';
import 'core/utils/settings_service.dart';
import 'core/services/signalr_service.dart';
import 'injection/injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await SettingsService.init();
  AppLocalizations.setLocale(SettingsService.languageCode);
  AppTheme.themeModeNotifier.value = 
      SettingsService.isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize dependency injection
  await configureDependencies();

  // Start SignalR
  sl<SignalRService>().init();

  runApp(const VibeApp());
}
