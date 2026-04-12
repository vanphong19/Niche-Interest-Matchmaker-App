class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://api.vibepulse.com/v1';

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';

  static const String createEvent = '/events';
  static const String nearbyEvents = '/events/nearby';

  static const String profile = '/profile';
  static const String updateProfile = '/profile/update';
}
