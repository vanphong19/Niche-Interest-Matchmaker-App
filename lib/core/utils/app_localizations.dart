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
      'profile': 'Profile',
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
      'delete_confirm':
          'This will permanently delete your account and all data. This action cannot be undone.',

      // Home
      'tonight_vibes': "Tonight's Vibes",
      'explore': 'Explore',
      'see_all': 'See All',
      'nearby_events': 'Nearby Events',
      'no_events_category': 'No more events found in this category.',
      'current_location': 'CURRENT LOCATION',
      'join_vibe': 'JOIN VIBE',

      // Vibe Match
      'vibe_match_title': 'Vibe Match',
      'vibe_match_label': 'MATCH',
      'vibe_match_headline': 'Great Alignment!',
      'vibe_match_subtitle':
          'You match well with this group\'s energy and interests.',
      'vibe_match_why': 'Why you match',
      'vibe_match_summary_title': 'Group vibe summary',
      'vibe_match_summary_body':
          'A laid-back group looking for casual evening kickarounds followed by late-night coffee runs. High energy but very welcoming to newcomers.',
      'vibe_match_going': 'going',
      'vibe_match_join_event': 'Join Event',
      'vibe_match_explore_matches': 'Explore Matches',
      'vibe_match_reason_football': 'Football Fans',
      'vibe_match_reason_night': 'Night Owls',
      'vibe_match_reason_nearby': 'Nearby (2km)',
      'vibe_match_reason_coffee': 'Coffee Lovers',
      'vibe_match_joined_title': 'You are in',
      'vibe_match_joined_headline': 'Spot reserved for tonight',
      'vibe_match_joined_body':
          'You joined the event successfully. We\'ll keep you posted on updates from the host.',
      'your_top_matches': 'Your Top Matches',
      'top_matches_subtitle':
          'Based on your recent vibes and shared interests, we think you\'d connect well with these folks.',
      'reliable': 'Reliable',
      'new': 'New',
      'late_risk': 'Late risk',
      'view_profile': 'View Profile',
      'shared': 'Shared',
      'no_matches_yet': 'No matches available yet.',

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
      'create_event_title_new': 'Create Event',
      'event_hero_title': 'Build a premium event profile',
      'event_hero_subtitle':
          'Balanced fields, clear hierarchy, and smooth interaction.',
      'event_section_core': 'Core Details',
      'event_section_core_subtitle': 'Identity, category, tags, and media.',
      'event_section_schedule': 'Schedule & Capacity',
      'event_section_schedule_subtitle':
          'Start/end timeline and participant limits.',
      'event_section_location': 'Location',
      'event_section_location_subtitle': 'Place details and map coordinates.',
      'event_section_advanced': 'Advanced Metadata',
      'event_section_advanced_subtitle':
          'Host, status, visibility, and AI score.',
      'event_field_id': 'Event ID',
      'event_field_title': 'Title',
      'event_field_title_hint': 'What is the vibe?',
      'event_field_description': 'Description',
      'event_field_description_hint':
          'Describe who should join and what to expect.',
      'event_field_category': 'Category',
      'event_field_vibe_tags': 'Vibe Tags',
      'event_field_add_tag': 'Add tag',
      'event_field_add_tag_hint': 'Chill, Competitive, Networking...',
      'event_field_photo_urls': 'Photo URLs',
      'event_field_add_photo_url': 'Add photo URL',
      'event_field_start_date': 'Start date',
      'event_field_start_time': 'Start time',
      'event_field_end_date': 'End date',
      'event_field_end_time': 'End time',
      'event_field_max_participants': 'Max participants',
      'event_field_current_participants': 'Current participants',
      'event_field_search_place': 'Search place',
      'event_field_search_place_hint': 'Type at least 2 characters...',
      'event_field_location_name': 'Location name',
      'event_field_location_name_hint': 'District 1 Center',
      'event_field_location_address': 'Address',
      'event_field_location_address_hint': 'Ho Chi Minh City, Vietnam',
      'event_field_latitude': 'Latitude',
      'event_field_longitude': 'Longitude',
      'event_field_host_id': 'Host ID',
      'event_field_host_name': 'Host name',
      'event_field_host_avatar': 'Host avatar URL',
      'event_field_place_id': 'Place ID',
      'event_field_place_id_hint': 'Optional external place id',
      'event_field_status': 'Status',
      'event_field_is_elite_only': 'Elite only visibility',
      'event_field_is_public': 'Public visibility',
      'event_field_is_joined': 'Joined by current user',
      'event_field_match_score': 'Match score',
      'event_field_participant_ids': 'Participant IDs',
      'event_field_participant_ids_hint': 'user-101, user-202...',
      'event_field_created_at': 'Created at',
      'event_status_draft': 'Draft',
      'event_status_active': 'Active',
      'event_status_cancelled': 'Cancelled',
      'event_status_completed': 'Completed',
      'event_category_sports': 'Sports',
      'event_category_dining': 'Dining',
      'event_category_social': 'Social',
      'event_category_arts': 'Arts',
      'event_category_outdoors': 'Outdoors',
      'event_category_gaming': 'Gaming',
      'event_create_button': 'Create Event',
      'event_create_loading': 'Creating event...',
      'event_create_success': 'Event created successfully!',
      'event_create_error': 'Error',
      'event_validation_title_description':
          'Please enter title and description.',
      'event_validation_location': 'Please enter location name and address.',
      'event_validation_end_time':
          'End date/time must be after start date/time.',

      // New additions for UI
      'appearance_desc':
          'Appearance settings are currently synced with Dark Mode toggle.',
      'privacy': 'Privacy',
      'privacy_desc':
          'Privacy & Visibility settings will be implemented in the next release.',
      'change_password_desc':
          'An email with instructions to change your password has been sent.',
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
      'profile': 'Hồ Sơ',
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
      'delete_confirm':
          'Điều này sẽ xóa vĩnh viễn tài khoản và tất cả dữ liệu. Hành động này không thể hoàn tác.',

      // Home
      'tonight_vibes': 'Chương Trình Tối Nay',
      'explore': 'Khám Phá',
      'match': 'Ghép Nhóm',
      'miles_short': 'dặm',
      'see_all': 'Xem Tất Cả',
      'nearby_events': 'Kèo Gần Đây',
      'no_events_category': 'Không tìm thấy sự kiện nào trong danh mục này.',
      'current_location': 'VỊ TRÍ HIỆN TẠI',
      'join_vibe': 'THAM GIA',

      // Vibe Match
      'vibe_match_title': 'Ghép Vibe',
      'vibe_match_label': 'TƯƠNG HỢP',
      'vibe_match_headline': 'Độ tương hợp rất tốt!',
      'vibe_match_subtitle':
          'Bạn phù hợp với năng lượng và sở thích của nhóm này.',
      'vibe_match_why': 'Vì sao hợp nhóm',
      'vibe_match_summary_title': 'Tóm tắt vibe nhóm',
      'vibe_match_summary_body':
          'Một nhóm thoải mái thích đá bóng buổi tối rồi đi cà phê đêm. Năng lượng cao nhưng luôn chào đón người mới.',
      'vibe_match_going': 'đang tham gia',
      'vibe_match_join_event': 'Tham Gia Sự Kiện',
      'vibe_match_explore_matches': 'Khám Phá Kết Nối',
      'vibe_match_reason_football': 'Fan Bóng Đá',
      'vibe_match_reason_night': 'Cú Đêm',
      'vibe_match_reason_nearby': 'Ở gần (2km)',
      'vibe_match_reason_coffee': 'Yêu Cà Phê',
      'vibe_match_joined_title': 'Bạn đã vào nhóm',
      'vibe_match_joined_headline': 'Đã giữ chỗ cho tối nay',
      'vibe_match_joined_body':
          'Bạn đã tham gia sự kiện thành công. Chúng tôi sẽ cập nhật thông tin mới từ host.',
      'your_top_matches': 'Top Kết Nối Của Bạn',
      'top_matches_subtitle':
          'Dựa trên vibe gần đây và sở thích chung, chúng tôi nghĩ bạn sẽ hợp với những người này.',
      'reliable': 'Đáng Tin Cậy',
      'new': 'Mới',
      'late_risk': 'Nguy Cơ Trễ',
      'view_profile': 'Xem Hồ Sơ',
      'shared': 'Tương Đồng',
      'no_matches_yet': 'Hiện chưa có kết nối phù hợp.',

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
      'create_event_title_new': 'Tạo Sự Kiện',
      'event_hero_title': 'Thiết kế sự kiện chuẩn cao cấp',
      'event_hero_subtitle':
          'Bố cục rõ ràng, trải nghiệm mượt và chuyên nghiệp.',
      'event_section_core': 'Thông Tin Chính',
      'event_section_core_subtitle':
          'Nhận diện sự kiện, danh mục, tag và hình ảnh.',
      'event_section_schedule': 'Lịch Trình & Sức Chứa',
      'event_section_schedule_subtitle':
          'Thời gian bắt đầu/kết thúc và giới hạn người tham gia.',
      'event_section_location': 'Địa Điểm',
      'event_section_location_subtitle':
          'Thông tin nơi tổ chức và tọa độ bản đồ.',
      'event_section_advanced': 'Metadata Nâng Cao',
      'event_section_advanced_subtitle':
          'Host, trạng thái, quyền hiển thị và điểm AI.',
      'event_field_id': 'Mã sự kiện',
      'event_field_title': 'Tiêu đề',
      'event_field_title_hint': 'Vibe của sự kiện là gì?',
      'event_field_description': 'Mô tả',
      'event_field_description_hint':
          'Mô tả đối tượng phù hợp và trải nghiệm mong đợi.',
      'event_field_category': 'Danh mục',
      'event_field_vibe_tags': 'Thẻ vibe',
      'event_field_add_tag': 'Thêm tag',
      'event_field_add_tag_hint': 'Chill, Competitive, Networking...',
      'event_field_photo_urls': 'Đường dẫn ảnh',
      'event_field_add_photo_url': 'Thêm URL ảnh',
      'event_field_start_date': 'Ngày bắt đầu',
      'event_field_start_time': 'Giờ bắt đầu',
      'event_field_end_date': 'Ngày kết thúc',
      'event_field_end_time': 'Giờ kết thúc',
      'event_field_max_participants': 'Số lượng tối đa',
      'event_field_current_participants': 'Số lượng hiện tại',
      'event_field_search_place': 'Tìm địa điểm',
      'event_field_search_place_hint': 'Nhập tối thiểu 2 ký tự...',
      'event_field_location_name': 'Tên địa điểm',
      'event_field_location_name_hint': 'District 1 Center',
      'event_field_location_address': 'Địa chỉ',
      'event_field_location_address_hint': 'Ho Chi Minh City, Vietnam',
      'event_field_latitude': 'Vĩ độ',
      'event_field_longitude': 'Kinh độ',
      'event_field_host_id': 'Host ID',
      'event_field_host_name': 'Tên host',
      'event_field_host_avatar': 'URL ảnh host',
      'event_field_place_id': 'Place ID',
      'event_field_place_id_hint': 'Mã địa điểm từ hệ thống ngoài (tuỳ chọn)',
      'event_field_status': 'Trạng thái',
      'event_field_is_elite_only': 'Chỉ hiển thị cho Elite',
      'event_field_is_public': 'Hiển thị công khai',
      'event_field_is_joined': 'Người dùng hiện tại đã tham gia',
      'event_field_match_score': 'Điểm tương hợp',
      'event_field_participant_ids': 'Danh sách participant IDs',
      'event_field_participant_ids_hint': 'user-101, user-202...',
      'event_field_created_at': 'Thời điểm tạo',
      'event_status_draft': 'Bản nháp',
      'event_status_active': 'Đang hoạt động',
      'event_status_cancelled': 'Đã hủy',
      'event_status_completed': 'Đã hoàn thành',
      'event_category_sports': 'Thể thao',
      'event_category_dining': 'Ăn uống',
      'event_category_social': 'Giao lưu',
      'event_category_arts': 'Nghệ thuật',
      'event_category_outdoors': 'Ngoài trời',
      'event_category_gaming': 'Gaming',
      'event_create_button': 'Tạo Sự Kiện',
      'event_create_loading': 'Đang tạo sự kiện...',
      'event_create_success': 'Tạo sự kiện thành công!',
      'event_create_error': 'Lỗi',
      'event_validation_title_description': 'Vui lòng nhập tiêu đề và mô tả.',
      'event_validation_location': 'Vui lòng nhập tên địa điểm và địa chỉ.',
      'event_validation_end_time':
          'Thời gian kết thúc phải sau thời gian bắt đầu.',

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
