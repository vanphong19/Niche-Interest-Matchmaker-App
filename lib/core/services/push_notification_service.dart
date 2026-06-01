import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/profile/data/services/user_api_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase is initialized by platform config when available.
  }
}

class PushNotificationService {
  PushNotificationService(this._userApiService);

  static const _channelId = 'vibepulse_notifications';
  static const _channelName = 'VibePulse notifications';
  static const _channelDescription = 'Friend requests and chat messages';

  final UserApiService _userApiService;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  FirebaseMessaging? _messaging;

  Future<void> initialize() async {
    if (_initialized) return;
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
    messaging.onTokenRefresh.listen((token) {
      registerCurrentDeviceToken(tokenOverride: token);
    });

    await registerCurrentDeviceToken();
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

    await _localNotifications.initialize(initSettings);
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
    final title = notification?.title ?? message.data['title'] ?? 'VibePulse';
    final body = notification?.body ?? message.data['body'] ?? '';

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
    );
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
