// lib/core/utils/app_localizations.dart
import 'package:flutter/material.dart';

/// Simple localization utility for VibePulse demo.
/// Supports English and Vietnamese.
class AppLocalizations {
  AppLocalizations._();

  static final ValueNotifier<String> localeNotifier = ValueNotifier('en');

  static String get currentLocale => localeNotifier.value;

  static String tr(String key) {
    final map = _translations[localeNotifier.value] ?? _translations['en']!;
    return map[key] ?? _translations['en']![key] ?? key;
  }

  static void setLocale(String code) {
    localeNotifier.value = code;
  }

  static const Map<String, Map<String, String>> _translations = {
    'en': {
      // General
      'app_name': 'VibePulse',
      'save': 'Save',
      'cancel': 'Cancel',
      'done': 'Done',
      'edit': 'Edit',
      'delete': 'Delete',
      'search': 'Search',
      'ok': 'OK',
      'loading': 'Loading...',

      // Profile
      'edit_profile': 'Edit Profile',
      'interests': 'Interests',
      'badges_gallery': 'Badges Gallery',
      'unlocked': 'UNLOCKED',
      'activity_history': 'Activity History',
      'view_all': 'VIEW ALL',
      'reputation_score': 'REPUTATION SCORE',
      'created': 'Created',
      'joined': 'Joined',
      'connections': 'Connections',
      'badges': 'Badges',
      'display_name': 'Display Name',
      'username': 'Username',
      'bio': 'Bio',
      'location': 'Location',
      'save_changes': 'Save Changes',
      'profile_updated': 'Profile updated successfully!',
      'select_interests': 'Select Interests',

      // Settings
      'settings': 'Settings',
      'preferences': 'PREFERENCES',
      'dark_mode': 'Dark Mode',
      'switch_dark': 'Switch to dark theme',
      'location_services': 'Location Services',
      'allow_location': 'Allow location access',
      'language': 'Language',
      'appearance': 'Appearance',
      'system_default': 'System Default',
      'notifications': 'NOTIFICATIONS',
      'push_notifications': 'Push Notifications',
      'get_updates': 'Get real-time updates',
      'email_notifications': 'Email Notifications',
      'weekly_digest': 'Weekly digest & updates',
      'event_reminders': 'Event Reminders',
      'remind_events': 'Remind before events',
      'account_safety': 'ACCOUNT & SAFETY',
      'privacy_visibility': 'Privacy & Visibility',
      'control_who': 'Control who sees your activity',
      'change_password': 'Change Password',
      'update_password': 'Update your password',
      'payout_settings': 'Payout Settings',
      'manage_earnings': 'Manage your hosting earnings',
      'help_center': 'Help Center',
      'faq_support': 'FAQs and support',
      'terms_service': 'Terms of Service',
      'legal_info': 'Legal information',
      'danger_zone': 'DANGER ZONE',
      'sign_out': 'Sign Out',
      'delete_account': 'Delete Account',
      'cannot_undone': 'This action cannot be undone',
      'select_language': 'Select Language',
      'sign_out_confirm': 'Are you sure you want to sign out?',
      'delete_confirm': 'This will permanently delete your account and all data. This action cannot be undone.',

      // Home
      'tonight_vibes': "Tonight's Vibes",
      'explore': 'Explore',
      'see_all': 'See All',
      'nearby_events': 'Kèo Gần Đây',
      'no_events_category': 'No more events found in this category.',
      'current_location': 'CURRENT LOCATION',
      'join_vibe': 'JOIN VIBE',

      // Map
      'search_placeholder': 'Search vibe, location or category...',
      'no_vibes_found': 'No public vibes found here.',

      // Activity
      'my_activity': 'My Activity',
      'hosting': 'Hosting',
      'past': 'Past',
      'no_events_yet': 'No events here yet',
      'starts_in_days': 'Starts in 2 days',
      'ended': 'Ended',
      'manage': 'Manage',
      'check_in': 'Check In',
      'rate_experience': 'Rate Experience',

      // Create Event
      'create_vibe': 'Create Vibe',
      'whats_vibe': "What's the Vibe?",
      'give_persona': 'Give your event a persona',
      'event_category': 'Event Category',
      'vibe_tags': 'Vibe Tags',
      'schedule_size': 'Schedule & Size',
      'when_how_many': 'When and how many?',
      'destination': 'The Destination',
      'where_happening': 'Where is it happening?',
      
      // New additions for UI
      'appearance_desc': 'Appearance settings are currently synced with Dark Mode toggle.',
      'privacy': 'Privacy',
      'privacy_desc': 'Privacy & Visibility settings will be implemented in the next release.',
      'change_password_desc': 'An email with instructions to change your password has been sent.',
      'payout': 'Payout',
      'payout_desc': 'Your Stripe account is currently connected successfully.',
      'help_desc': 'Redirecting to support portal...',
      'terms': 'Terms',
      'terms_desc': 'Loading terms of service...',
      'version': 'Version 1.0.0 (Build 42)',
      'made_with': 'Made with 💜 in HCMC',
      'language_changed': 'Language changed to',
      'your_display_name': 'Your display name',
      'name_required': 'Name is required',
      'your_username': 'Your username',
      'username_required': 'Username is required',
      'email': 'EMAIL',
      'your_email': 'Your email',
      'tell_people': 'Tell people about yourself...',
      'your_city': 'Your city',
      'tap_change_photo': 'Tap to change photo',
      'avatar_updated': 'Avatar updated!',
      'message': 'Message',
      'follow': 'Follow',
      'following': 'Following',
    },
    'vi': {
      // General
      'app_name': 'VibePulse',
      'save': 'Lưu',
      'cancel': 'Hủy',
      'done': 'Xong',
      'edit': 'Sửa',
      'delete': 'Xóa',
      'search': 'Tìm kiếm',
      'ok': 'OK',
      'loading': 'Đang tải...',

      // Profile
      'edit_profile': 'Chỉnh Sửa Hồ Sơ',
      'interests': 'Sở Thích',
      'badges_gallery': 'Bộ Sưu Tập Huy Hiệu',
      'unlocked': 'ĐÃ MỞ',
      'activity_history': 'Lịch Sử Hoạt Động',
      'view_all': 'XEM TẤT CẢ',
      'reputation_score': 'ĐIỂM UY TÍN',
      'created': 'Đã tạo',
      'joined': 'Đã tham gia',
      'connections': 'Kết nối',
      'badges': 'Huy hiệu',
      'display_name': 'Tên hiển thị',
      'username': 'Tên người dùng',
      'bio': 'Tiểu sử',
      'location': 'Vị trí',
      'save_changes': 'Lưu Thay Đổi',
      'profile_updated': 'Hồ sơ đã cập nhật thành công!',
      'select_interests': 'Chọn Sở Thích',

      // Settings
      'settings': 'Cài Đặt',
      'preferences': 'TÙY CHỌN',
      'dark_mode': 'Chế Độ Tối',
      'switch_dark': 'Chuyển sang giao diện tối',
      'location_services': 'Dịch Vụ Vị Trí',
      'allow_location': 'Cho phép truy cập vị trí',
      'language': 'Ngôn Ngữ',
      'appearance': 'Giao Diện',
      'system_default': 'Mặc Định Hệ Thống',
      'notifications': 'THÔNG BÁO',
      'push_notifications': 'Thông Báo Đẩy',
      'get_updates': 'Nhận cập nhật thời gian thực',
      'email_notifications': 'Thông Báo Email',
      'weekly_digest': 'Tóm tắt & cập nhật hàng tuần',
      'event_reminders': 'Nhắc Nhở Sự Kiện',
      'remind_events': 'Nhắc nhở trước sự kiện',
      'account_safety': 'TÀI KHOẢN & BẢO MẬT',
      'privacy_visibility': 'Quyền Riêng Tư',
      'control_who': 'Kiểm soát ai xem hoạt động của bạn',
      'change_password': 'Đổi Mật Khẩu',
      'update_password': 'Cập nhật mật khẩu của bạn',
      'payout_settings': 'Cài Đặt Thanh Toán',
      'manage_earnings': 'Quản lý thu nhập từ tổ chức',
      'help_center': 'Trung Tâm Trợ Giúp',
      'faq_support': 'Câu hỏi thường gặp & hỗ trợ',
      'terms_service': 'Điều Khoản Dịch Vụ',
      'legal_info': 'Thông tin pháp lý',
      'danger_zone': 'VÙNG NGUY HIỂM',
      'sign_out': 'Đăng Xuất',
      'delete_account': 'Xóa Tài Khoản',
      'cannot_undone': 'Hành động này không thể hoàn tác',
      'select_language': 'Chọn Ngôn Ngữ',
      'sign_out_confirm': 'Bạn có chắc muốn đăng xuất?',
      'delete_confirm': 'Điều này sẽ xóa vĩnh viễn tài khoản và tất cả dữ liệu. Hành động này không thể hoàn tác.',

      // Home
      'tonight_vibes': 'Chương Trình Tối Nay',
      'explore': 'Khám Phá',
      'see_all': 'Xem Tất Cả',
      'nearby_events': 'Kèo Gần Đây',
      'no_events_category': 'Không tìm thấy sự kiện nào trong danh mục này.',
      'current_location': 'VỊ TRÍ HIỆN TẠI',
      'join_vibe': 'THAM GIA',

      // Map
      'search_placeholder': 'Tìm vibe, địa điểm hoặc danh mục...',
      'no_vibes_found': 'Không tìm thấy vibe nào ở đây.',

      // Activity
      'my_activity': 'Hoạt Động',
      'hosting': 'Đang tổ chức',
      'past': 'Đã qua',
      'no_events_yet': 'Chưa có sự kiện nào',
      'starts_in_days': 'Bắt đầu trong 2 ngày',
      'ended': 'Đã kết thúc',
      'manage': 'Quản lý',
      'check_in': 'Điểm danh',
      'rate_experience': 'Đánh giá',

      // Create Event
      'create_vibe': 'Tạo Kèo',
      'whats_vibe': 'Vibe Của Bạn?',
      'give_persona': 'Đặt tên cho sự kiện',
      'event_category': 'Danh Mục Sự Kiện',
      'vibe_tags': 'Thẻ Vibe',
      'schedule_size': 'Lịch Trình & Quy Mô',
      'when_how_many': 'Khi nào và bao nhiêu người?',
      'destination': 'Địa Điểm',
      'where_happening': 'Diễn ra ở đâu?',
      
      // New additions for UI
      'appearance_desc': 'Cài đặt giao diện hiện đang đồng bộ với chế độ tối.',
      'privacy': 'Quyền Riêng Tư',
      'privacy_desc': 'Cài đặt Quyền riêng tư sẽ có trong bản cập nhật tới.',
      'change_password_desc': 'Một email hướng dẫn đổi mật khẩu đã được gửi.',
      'payout': 'Thanh Toán',
      'payout_desc': 'Tài khoản Stripe của bạn đã được kết nối thành công.',
      'help_desc': 'Đang chuyển hướng đến cổng hỗ trợ...',
      'terms': 'Điều Khoản',
      'terms_desc': 'Đang tải điều khoản dịch vụ...',
      'version': 'Phiên bản 1.0.0 (Build 42)',
      'made_with': 'Làm với 💜 tại TP.HCM',
      'language_changed': 'Đã đổi ngôn ngữ sang',
      'your_display_name': 'Tên hiển thị của bạn',
      'name_required': 'Vui lòng nhập tên',
      'your_username': 'Tên người dùng của bạn',
      'username_required': 'Vui lòng nhập tên người dùng',
      'email': 'EMAIL',
      'your_email': 'Email của bạn',
      'tell_people': 'Giới thiệu về bản thân...',
      'your_city': 'Thành phố của bạn',
      'tap_change_photo': 'Chạm để đổi ảnh',
      'avatar_updated': 'Đã cập nhật ảnh đại diện!',
      'message': 'Nhắn tin',
      'follow': 'Theo dõi',
      'following': 'Đang theo dõi',
    },
    'ja': {
      'app_name': 'VibePulse',
      'settings': '設定',
      'edit_profile': 'プロフィール編集',
      'interests': '趣味',
      'badges_gallery': 'バッジギャラリー',
      'activity_history': 'アクティビティ履歴',
      'view_all': 'すべて見る',
      'dark_mode': 'ダークモード',
      'language': '言語',
      'sign_out': 'ログアウト',
    },
    'ko': {
      'app_name': 'VibePulse',
      'settings': '설정',
      'edit_profile': '프로필 편집',
      'interests': '관심사',
      'badges_gallery': '배지 갤러리',
      'activity_history': '활동 내역',
      'view_all': '모두 보기',
      'dark_mode': '다크 모드',
      'language': '언어',
      'sign_out': '로그아웃',
    },
    'fr': {
      'app_name': 'VibePulse',
      'settings': 'Paramètres',
      'edit_profile': 'Modifier le profil',
      'interests': 'Centres d\'intérêt',
      'badges_gallery': 'Galerie de badges',
      'activity_history': 'Historique d\'activité',
      'view_all': 'TOUT VOIR',
      'dark_mode': 'Mode sombre',
      'language': 'Langue',
      'sign_out': 'Déconnexion',
    },
  };

  static String langCodeToName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'vi':
        return 'Tiếng Việt';
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      case 'fr':
        return 'Français';
      default:
        return code;
    }
  }

  static String langNameToCode(String name) {
    switch (name) {
      case 'English':
        return 'en';
      case 'Vietnamese':
      case 'Tiếng Việt':
        return 'vi';
      case 'Japanese':
      case '日本語':
        return 'ja';
      case 'Korean':
      case '한국어':
        return 'ko';
      case 'French':
      case 'Français':
        return 'fr';
      default:
        return 'en';
    }
  }
}
