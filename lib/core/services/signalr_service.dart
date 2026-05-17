import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';

@lazySingleton
class SignalRService {
  final FlutterSecureStorage _storage;
  HubConnection? _hubConnection;
  bool _isStarting = false;

  final _eventStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get eventStatusStream =>
      _eventStatusController.stream;
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;
  final _friendshipController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get friendshipStream =>
      _friendshipController.stream;
  final _matchController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get matchStream => _matchController.stream;
  final _dataChangeController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get dataChangeStream =>
      _dataChangeController.stream;

  SignalRService(this._storage);

  Future<void> init() async {
    if (_isStarting || _hubConnection?.state == HubConnectionState.Connected) {
      return;
    }

    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token == null) return;

    final url = '${ApiConstants.baseUrl}/hubs/event';
    _isStarting = true;

    _hubConnection = HubConnectionBuilder()
        .withUrl(
          url,
          options: HttpConnectionOptions(
            accessTokenFactory: () async =>
                await _storage.read(key: AppConstants.tokenKey) ?? token,
          ),
        )
        .withAutomaticReconnect()
        .build();

    void bindMany(
      Iterable<String> names,
      StreamController<Map<String, dynamic>> controller,
      String type,
    ) {
      for (final name in names) {
        _hubConnection?.on(name, (arguments) {
          final data = _normalizePayload(arguments);
          final payload = {...data, '_type': type, '_event': name};
          controller.add(payload);
          _dataChangeController.add(payload);
        });
      }
    }

    bindMany(
      const [
        'OnEventStatusChanged',
        'EventStatusChanged',
        'EventChanged',
        'MatchChanged',
        'ParticipantChanged',
        'JoinRequestChanged',
        'JoinRequestAccepted',
        'JoinRequestApproved',
        'UserJoinedEvent',
        'UserLeftEvent',
        'EventDeleted',
      ],
      _eventStatusController,
      'event',
    );
    bindMany(
      const [
        'OnNotificationCreated',
        'NotificationCreated',
        'NotificationChanged',
      ],
      _notificationController,
      'notification',
    );
    bindMany(
      const [
        'OnFriendshipChanged',
        'FriendshipChanged',
        'FriendRequestChanged',
      ],
      _friendshipController,
      'friendship',
    );
    bindMany(
      const ['OnMatchChanged', 'MatchChanged', 'MatchUpdated'],
      _matchController,
      'match',
    );

    try {
      await _hubConnection?.start();
      debugPrint('SignalR: Connected');
    } catch (e) {
      debugPrint('SignalR: Connection failed: $e');
    } finally {
      _isStarting = false;
    }
  }

  Map<String, dynamic> _normalizePayload(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty || arguments.first == null) {
      return {};
    }
    final first = arguments.first;
    if (first is Map<String, dynamic>) return first;
    if (first is Map) return Map<String, dynamic>.from(first);
    return {'value': first.toString()};
  }

  void emitLocalChange(String type, [Map<String, dynamic> data = const {}]) {
    final payload = {...data, '_type': type, '_event': 'local'};
    _dataChangeController.add(payload);
    switch (type) {
      case 'event':
        _eventStatusController.add(payload);
        break;
      case 'notification':
        _notificationController.add(payload);
        break;
      case 'friendship':
        _friendshipController.add(payload);
        break;
      case 'match':
        _matchController.add(payload);
        break;
    }
  }

  Future<void> stop() async {
    await _hubConnection?.stop();
    _hubConnection = null;
  }
}
