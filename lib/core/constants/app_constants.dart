// lib/core/constants/app_constants.dart
class AppConstants {
  AppConstants._();

  static const String appName = 'VibePulse';
  static const String appTagline = 'Find Your Vibe, Find Your Crew';
  static const String appVersion = '1.0.0';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 15);

  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration snackBarDuration = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration debounceDelay = Duration(milliseconds: 500);

  static const int maxEventImagesCount = 5;
  static const int maxBioLength = 250;
  static const int maxEventDescriptionLength = 1000;
  static const int minPasswordLength = 8;
  static const int maxParticipants = 100;

  static const double defaultMapZoom = 14.0;
  static const double nearbyRadius = 10.0; // km
  static const double defaultLat = 10.8231;
  static const double defaultLng = 106.6297;

  static const String tokenKey = 'jwt_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String localeKey = 'locale';
  static const String onboardingKey = 'onboarding_done';
}
