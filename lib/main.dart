// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_localizations.dart';
import 'core/utils/profile_state.dart';
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
  AppTheme.themeModeNotifier.value = SettingsService.isDarkMode
      ? ThemeMode.dark
      : ThemeMode.light;

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

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://kzulsoyrjrsnhpnygxxt.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt6dWxzb3lyanJzbmhwbnlneHh0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc1NDY2OTIsImV4cCI6MjA5MzEyMjY5Mn0.7RqdB70vLG5pQsBQmyjwRZ9Yx_2t8sOG8PxuE3Xtw3Q',
  );

  // Initialize dependency injection
  await configureDependencies();

  // Start SignalR
  sl<SignalRService>().init();
  sl<SignalRService>().dataChangeStream.listen((_) => ProfileState.init());

  runApp(const VibeApp());
}
