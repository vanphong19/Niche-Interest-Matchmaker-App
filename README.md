# VibePulse Mobile App

## 1. Overview

`niche_interest_matchmaker_app` là mobile app Flutter của VibePulse/Niche Interest Matchmaker. App giúp người dùng đăng ký, khám phá sự kiện theo sở thích, tham gia hoạt động, vibe check với người khác, chat realtime, check-in bằng GPS/QR/NFC và quản lý hồ sơ/điểm uy tín.

Backend API tương ứng nằm ở `../niche-interest-matchmaker`.

## 2. Features

- Auth flow: splash, login, register, forgot password, social login.
- Home/map discovery để khám phá sự kiện và địa điểm.
- Tạo, xem chi tiết, chỉnh sửa, quản lý và tham gia sự kiện.
- Vibe Check cá nhân/nhóm và danh sách kết quả tương thích.
- Chat inbox, group chat theo event và direct message.
- Check-in bằng GPS, QR scanner và NFC.
- Find In Crowd: gửi/nhận yêu cầu tìm người trong sự kiện, radar/camera/location UI.
- Profile, public profile, chỉnh sửa hồ sơ, lịch sử hoạt động, bạn bè.
- Trust/reputation dashboard.
- Settings, đổi mật khẩu, help center, terms, privacy.
- Push notification và SignalR realtime.

## 3. Tech Stack

| Nhóm                                          | Công nghệ                                                                                                   |
| --------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| Frontend / Mobile                             | Flutter, Dart `^3.10.7`, Material/Cupertino UI, BLoC, auto_route, get_it/injectable                         |
| Backend                                       | ASP.NET Core API ở `../niche-interest-matchmaker`                                                           |
| Database                                      | Backend dùng PostgreSQL/Supabase; app có `supabase_flutter` và `supabase_trigger.sql`                       |
| Admin Dashboard                               | Next.js dashboard ở `../niche-interest-matchmaker/niche-interest-matchmaker-admin`                          |
| Realtime / Authentication / External Services | SignalR client, Firebase Messaging, Supabase Flutter, Google Sign-In, Facebook Auth, flutter_secure_storage |

## 4. Project Structure

```bash
niche_interest_matchmaker_app/
├── android/                         # Android native project, flavors, google-services.json
├── ios/                             # iOS native project
├── lib/
│   ├── core/                        # Constants, network, services, theme, widgets, utils
│   ├── features/
│   │   ├── auth/                    # Login/register/forgot password
│   │   ├── base/                    # Main shell, bottom navigation
│   │   ├── chat/                    # Chat inbox, DM, event group chat
│   │   ├── checkin/                 # GPS/QR/NFC check-in UI
│   │   ├── event/                   # Create/detail/manage/edit event
│   │   ├── find_in_crowd/           # Finder request/session/location UI
│   │   ├── home/                    # Home and map discovery
│   │   ├── profile/                 # Profile, edit, public profile
│   │   ├── settings/                # Settings and legal/help pages
│   │   ├── trust/                   # Reputation/trust UI
│   │   └── vibe_check/              # Vibe check screens/blocs/widgets
│   ├── injection/                   # Dependency injection
│   ├── router/                      # auto_route config
│   ├── app.dart
│   └── main.dart
├── test/
├── web/
├── windows/
├── pubspec.yaml
├── supabase_trigger.sql
└── README.md
```

## 5. Prerequisites

- Flutter SDK có Dart `^3.10.7`.
- Android Studio và Android SDK nếu chạy Android.
- Xcode nếu chạy iOS.
- Chrome nếu chạy Flutter Web.
- Backend API đang chạy local hoặc deploy.
- Firebase project/file cấu hình nếu dùng push notification.
- Supabase project nếu dùng Supabase Auth/social login.

## 6. Installation

```powershell
cd niche_interest_matchmaker_app
flutter pub get
```

Project dùng code generation cho `auto_route`, `freezed`, `json_serializable`, `injectable`. Chạy sau khi clone hoặc sau khi sửa route/model/DI:

```powershell
dart run build_runner build --delete-conflicting-outputs
```

Kiểm tra thiết bị:

```powershell
flutter devices
```

## 7. Configuration

### API Base URL

API base URL nằm trong:

```text
lib/core/constants/api_constants.dart
```

Hiện tại `ApiConstants.baseUrl` đang trỏ đến backend deploy. Khi chạy local, đổi theo target:

```dart
static String get baseUrl {
  return 'http://10.0.2.2:5230';
}
```

Gợi ý URL:

| Target                   | URL                                         |
| ------------------------ | ------------------------------------------- |
| Android emulator         | `http://10.0.2.2:5230`                      |
| Chrome/Windows desktop   | `http://localhost:5230`                     |
| Thiết bị thật cùng Wi-Fi | `http://<IP-LAN-cua-may-chay-backend>:5230` |

### Firebase

Android có file:

```text
android/app/google-services.json
```

File này cần hợp lệ nếu dùng Firebase Messaging. Không commit file Firebase mới chứa secret/private config ngoài ý muốn.

### Supabase

`main.dart` khởi tạo Supabase bằng URL và anon key. Repo cũng có:

```text
supabase_trigger.sql
```

File SQL này tạo trigger để đồng bộ user mới từ `auth.users` sang `public.users`. Chạy trong Supabase Dashboard > SQL Editor nếu dùng Supabase Auth.

## 8. Running the Project

### Mobile App

Chạy Android emulator hoặc thiết bị:

```powershell
flutter run --flavor dev -d <device-id>
```

Chạy Flutter Web:

```powershell
flutter run -d chrome
```

Chạy Windows desktop:

```powershell
flutter run -d windows
```

### Backend

Chạy backend trước nếu test local:

```powershell
cd ..\niche-interest-matchmaker
dotnet run --project .\niche-interest-matchmaker\niche-interest-matchmaker.csproj --launch-profile http
```

Backend mặc định chạy ở `http://localhost:5230`.

### Admin Dashboard

```powershell
cd ..\niche-interest-matchmaker\niche-interest-matchmaker-admin
npm install
npm run dev
```

Mở `http://localhost:3000`.

## 9. Database Setup

Mobile app không chạy migration trực tiếp. Database được quản lý bởi backend ASP.NET Core qua EF Core migrations.

Nếu dùng Supabase Auth/social login, chạy `supabase_trigger.sql` trong Supabase SQL Editor để tạo trigger đồng bộ user:

```sql
-- Xem nội dung đầy đủ trong supabase_trigger.sql
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER AS $$
...
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

Không ghi connection string hoặc service role key vào app mobile.

## 10. API Documentation

Backend API có Swagger tại `http://localhost:5230/swagger`.

Các nhóm API mobile sử dụng chính:

| Method   | Endpoint                                        | Description                 |
| -------- | ----------------------------------------------- | --------------------------- |
| POST     | `/api/auth/login`                               | Đăng nhập                   |
| POST     | `/api/auth/register`                            | Đăng ký                     |
| POST     | `/api/auth/refresh`                             | Refresh token               |
| GET      | `/api/auth/me`                                  | Lấy thông tin user hiện tại |
| GET/PUT  | `/api/app/profile`                              | Lấy/cập nhật hồ sơ          |
| GET/POST | `/api/app/profile/friends`                      | Quản lý bạn bè              |
| GET      | `/api/app/profile/notifications`                | Lấy thông báo               |
| GET/POST | `/api/app/matches`                              | Danh sách/tạo sự kiện       |
| GET      | `/api/app/matches/nearby`                       | Sự kiện gần vị trí hiện tại |
| POST     | `/api/app/matches/{id}/join`                    | Tham gia sự kiện            |
| POST     | `/api/app/matches/{id}/leave`                   | Rời sự kiện                 |
| GET      | `/api/app/places`                               | Danh sách địa điểm          |
| GET/POST | `/api/app/checkins`                             | Check-in GPS/QR             |
| POST     | `/api/app/checkins/nfc`                         | Check-in NFC                |
| POST     | `/api/vibe-check`                               | Vibe check cá nhân          |
| POST     | `/api/vibe-check/group`                         | Vibe check nhóm             |
| GET      | `/api/vibe-check/history`                       | Lịch sử vibe check          |
| GET      | `/api/chat-rooms/{chatRoomId}/messages`         | Lấy tin nhắn                |
| POST     | `/api/chat-rooms/{chatRoomId}/read`             | Đánh dấu đã đọc             |
| POST     | `/api/app/matches/{eventId}/finder/requests`    | Gửi yêu cầu Find In Crowd   |
| POST     | `/api/app/finder/sessions/{sessionId}/location` | Cập nhật vị trí finder      |

SignalR hubs:

| Hub   | URL           |
| ----- | ------------- |
| Chat  | `/hubs/chat`  |
| Event | `/hubs/event` |

## 11. Notes

- Android emulator cần dùng `10.0.2.2` để gọi backend trên máy host.
- Thiết bị thật cần cùng Wi-Fi với máy chạy backend và firewall mở port `5230`.
- Check-in QR cần quyền camera.
- Check-in NFC cần thiết bị hỗ trợ NFC và quyền/cấu hình NFC tương ứng.
- Find In Crowd, map discovery và GPS check-in cần quyền location.
- Push notification cần Firebase Messaging hoạt động đúng.
- Sau khi sửa generated route/model/DI, chạy lại `build_runner`.
- Không commit secret mới vào `main.dart`, `api_constants.dart`, Firebase config hoặc file môi trường.

## 12. Contributors

- 22521083 - Đỗ Văn Phong
- 22520892 - Trần Văn Minh
- 22520912 - Lê Xuân Nam
