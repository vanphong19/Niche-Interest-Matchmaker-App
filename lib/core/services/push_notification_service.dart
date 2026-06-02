import 'dart:convert';
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/chat/data/models/chat_room_model.dart';
import '../../features/chat/data/services/chat_api_service.dart';
import '../../features/chat/presentation/pages/chat_detail_page.dart';
import '../../features/home/presentation/widgets/notifications_panel.dart';
import '../../features/profile/data/services/user_api_service.dart';
import '../../router/app_router.dart';
import '../../router/app_router.gr.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase is initialized by platform config when available.
  }
}

class PushNotificationService {
  PushNotificationService(this._userApiService, this._chatApiService);

  static const _channelId = 'vibepulse_notifications';
  static const _channelName = 'VibePulse notifications';
  static const _channelDescription = 'Friend requests and chat messages';

  final UserApiService _userApiService;
  final ChatApiService _chatApiService;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  FirebaseMessaging? _messaging;
  bool _openingChatFromNotification = false;
  bool get isOpeningChatFromNotification => _openingChatFromNotification;

  Future<void> initialize() async {
    _initialized = true;

    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase init skipped/failed: $e');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    _messaging = messaging;

    await messaging.requestPermission(alert: true, badge: true, sound: true);
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    await _initLocalNotifications();

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessageOpened);
    messaging.onTokenRefresh.listen((token) {
      registerCurrentDeviceToken(tokenOverride: token);
    });
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      unawaited(_handleRemoteMessageOpened(initialMessage));
    }
  }

  Future<void> registerCurrentDeviceToken({String? tokenOverride}) async {
    try {
      final messaging = _messaging;
      if (messaging == null) return;
      final token = tokenOverride ?? await messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _userApiService.registerDeviceToken(
        token: token,
        platform: _platformName,
      );
    } catch (e) {
      debugPrint('Register FCM token failed: $e');
    }
  }

  Future<void> unregisterCurrentDeviceToken() async {
    try {
      final messaging = _messaging;
      if (messaging == null) return;
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _userApiService.unregisterDeviceToken(
        token: token,
        platform: _platformName,
      );
    } catch (e) {
      debugPrint('Unregister FCM token failed: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.high,
          ),
        );
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final chatText = await _chatNotificationText(message);
    final title =
        chatText?.title ??
        _notificationTitle(message) ??
        notification?.title ??
        message.data['title'] ??
        'VibePulse';
    final body =
        chatText?.body ??
        _notificationBody(message) ??
        notification?.body ??
        message.data['body'] ??
        '';

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  String? _notificationTitle(RemoteMessage message) {
    final data = message.data;
    if (!_isChatPayload(data)) return null;

    final roomType = _read(data, [
      'chatRoomType',
      'roomType',
      'type',
      'conversationType',
    ]).toLowerCase();
    final isGroup = roomType.contains('group');
    if (isGroup) {
      return _read(data, ['chatRoomName', 'roomName', 'groupName', 'name']);
    }

    final senderName = _read(data, ['senderName', 'SenderName']);
    return senderName.isNotEmpty ? senderName : null;
  }

  String? _notificationBody(RemoteMessage message) {
    final data = message.data;
    if (!_isChatPayload(data)) return null;

    final content = _read(data, ['content', 'message', 'body', 'text']);
    if (content.isEmpty) return null;

    final roomType = _read(data, [
      'chatRoomType',
      'roomType',
      'type',
      'conversationType',
    ]).toLowerCase();
    final isGroup = roomType.contains('group');
    if (!isGroup) return content;

    final senderName = _read(data, ['senderName', 'SenderName']);
    return senderName.isEmpty ? content : '$senderName: $content';
  }

  Future<_NotificationText?> _chatNotificationText(
    RemoteMessage message,
  ) async {
    final data = message.data;
    if (!_isChatPayload(data)) return null;

    final room = await _roomFromPayload(data);
    final fallbackTitle = _notificationTitle(message);
    final fallbackBody =
        _notificationBody(message) ??
        message.notification?.body ??
        _read(data, ['body', 'message', 'content', 'text']);

    if (room == null) {
      if (fallbackTitle == null && fallbackBody.isEmpty) return null;
      return _NotificationText(
        title: fallbackTitle ?? 'Tin nhắn mới',
        body: fallbackBody,
      );
    }

    final senderName = _read(data, ['senderName', 'SenderName']);
    final rawContent = _read(data, ['content', 'message', 'body', 'text']);
    final content = rawContent.isNotEmpty ? rawContent : fallbackBody;

    if (room.isGroup) {
      final title = room.name.trim().isNotEmpty
          ? room.name.trim()
          : fallbackTitle ?? 'Tin nhắn nhóm';
      final body = senderName.isEmpty || content.startsWith('$senderName:')
          ? content
          : '$senderName: $content';
      return _NotificationText(title: title, body: body);
    }

    final title = senderName.isNotEmpty
        ? senderName
        : room.name.trim().isNotEmpty
        ? room.name.trim()
        : fallbackTitle ?? 'Tin nhắn riêng';
    return _NotificationText(title: title, body: _stripSenderPrefix(content));
  }

  bool _isChatPayload(Map<String, dynamic> data) {
    return _read(data, ['chatRoomId', 'ChatRoomId', 'roomId']).isNotEmpty;
  }

  Future<void> _handleRemoteMessageOpened(RemoteMessage message) async {
    await _openFromPayload(message.data);
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        unawaited(_openFromPayload(decoded));
      }
    } catch (e) {
      debugPrint('Notification payload parse failed: $e');
    }
  }

  Future<void> _openChatFromPayload(Map<String, dynamic> data) async {
    final chatRoomId = _read(data, ['chatRoomId', 'ChatRoomId', 'roomId']);
    if (chatRoomId.isEmpty) return;

    try {
      final room = await _roomFromPayload(data);
      if (room == null) return;

      _markOpeningChatFromNotification();
      await Future<void>.delayed(const Duration(milliseconds: 250));
      final appRouter = AppRouterProvider.instance;
      if (_isAuthRoute(appRouter.current.name)) {
        await appRouter.replaceAll([const BaseRoute()]);
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }

      final navigator = appRouter.navigatorKey.currentState;
      if (navigator == null) return;

      await navigator.push<void>(
        MaterialPageRoute(builder: (_) => ChatDetailPage(room: room)),
      );
    } catch (e) {
      debugPrint('Open chat notification failed: $e');
    }
  }

  Future<void> _openFromPayload(Map<String, dynamic> data) async {
    if (_isChatPayload(data)) {
      await _openChatFromPayload(data);
      return;
    }

    await _openNotificationsPanelFromPayload();
  }

  Future<void> _openNotificationsPanelFromPayload() async {
    try {
      _markOpeningChatFromNotification();
      await Future<void>.delayed(const Duration(milliseconds: 250));
      final appRouter = AppRouterProvider.instance;
      if (_isAuthRoute(appRouter.current.name)) {
        await appRouter.replaceAll([const BaseRoute()]);
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }

      final navigator = appRouter.navigatorKey.currentState;
      if (navigator == null || !navigator.mounted) return;

      await showModalBottomSheet<void>(
        context: navigator.context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const NotificationsPanel(),
      );
    } catch (e) {
      debugPrint('Open notifications panel failed: $e');
    }
  }

  Future<ChatRoomModel?> _roomFromPayload(Map<String, dynamic> data) async {
    final chatRoomId = _read(data, ['chatRoomId', 'ChatRoomId', 'roomId']);
    if (chatRoomId.isEmpty) return null;

    final rooms = await _chatApiService.getMyRooms();
    return rooms.cast<ChatRoomModel?>().firstWhere(
      (r) => r?.id.toLowerCase() == chatRoomId.toLowerCase(),
      orElse: () => null,
    );
  }

  void _markOpeningChatFromNotification() {
    _openingChatFromNotification = true;
    // _openingChatResetTimer?.cancel();
    // _openingChatResetTimer = Timer(const Duration(seconds: 8), () {
    //   _openingChatFromNotification = false;
    // });
  }

  bool _isAuthRoute(String routeName) {
    return routeName == SplashRoute.name ||
        routeName == LoginRoute.name ||
        routeName == RegisterRoute.name ||
        routeName == ForgotPasswordRoute.name;
  }

  String _read(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  String _stripSenderPrefix(String content) {
    final separatorIndex = content.indexOf(':');
    if (separatorIndex <= 0) return content;

    final possibleName = content.substring(0, separatorIndex).trim();
    final message = content.substring(separatorIndex + 1).trim();
    if (possibleName.isEmpty || message.isEmpty) return content;
    if (possibleName.length > 40) return content;
    return message;
  }

  String get _platformName {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }
}

class _NotificationText {
  const _NotificationText({required this.title, required this.body});

  final String title;
  final String body;
}
