// lib/core/constants/api_constants.dart
class ApiConstants {
  ApiConstants._();

  // Tự động chọn URL: localhost cho Web/iOS, 10.0.2.2 cho Android Emulator
  static String get baseUrl {
    // Nếu chạy trên Web hoặc không phải Android Emulator thì dùng localhost
    // Vì bạn đang test trên trình duyệt nên tôi đổi mặc định về localhost:5230
    return 'http://localhost:5230'; 
  }

  // ─── Auth ─────────────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String verifyOtp = '/auth/verify-otp';
  static const String logout = '/auth/logout';
  static const String socialLogin = '/auth/social-login';

  // ─── User / Profile ───────────────────────────────────────────────
  static const String profile = '/users/me';
  static const String updateProfile = '/users/me';
  static const String uploadAvatar = '/users/me/avatar';
  static const String userById = '/users'; // /users/:id

  // ─── Events ───────────────────────────────────────────────────────
  static const String events = '/events';
  static const String nearbyEvents = '/events/nearby';
  static const String eventById = '/events'; // /events/:id
  static const String joinEvent = '/events'; // /events/:id/join
  static const String leaveEvent = '/events'; // /events/:id/leave
  static const String eventCategories = '/events/categories';
  static const String myEvents = '/events/me';
  static const String trendingEvents = '/events/trending';

  // ─── Map ──────────────────────────────────────────────────────────
  static const String mapMarkers = '/map/markers';
  static const String mapSearch = '/map/search';

  // ─── Notifications ────────────────────────────────────────────────
  static const String notifications = '/notifications';
  static const String markRead = '/notifications/read';

  // ─── Badges ───────────────────────────────────────────────────────
  static const String badges = '/badges';
  static const String badgeById = '/badges'; // /badges/:id
  static const String myBadges = '/badges/me';

  // ─── Settings ─────────────────────────────────────────────────────
  static const String settings = '/settings';
  static const String deleteAccount = '/settings/delete-account';
}
