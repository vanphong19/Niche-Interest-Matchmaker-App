// lib/features/chat/data/services/signalr_chat_service.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/chat_room_model.dart';

/// Quản lý kết nối SignalR tới /hubs/chat
/// Pattern tương tự SignalRService hiện có (EventHub)
class SignalRChatService {
  final FlutterSecureStorage _storage;
  HubConnection? _connection;
  bool _isStarting = false;

  // ─── Streams ──────────────────────────────────────────────────────────────

  final _messageController = StreamController<ChatMessageModel>.broadcast();
  Stream<ChatMessageModel> get onMessageReceived => _messageController.stream;

  final _typingController = StreamController<TypingEventModel>.broadcast();
  Stream<TypingEventModel> get onUserTyping => _typingController.stream;

  final _presenceController = StreamController<PresenceEventModel>.broadcast();
  Stream<PresenceEventModel> get onPresenceChanged =>
      _presenceController.stream;

  final _connectionStateController = StreamController<String>.broadcast();
  Stream<String> get connectionState => _connectionStateController.stream;

  SignalRChatService(this._storage);

  // ─── Connect ─────────────────────────────────────────────────────────────

  Future<void> connect() async {
    if (_isStarting) return;
    if (_connection?.state == HubConnectionState.Connected) {
      debugPrint('SignalRChat: Already connected');
      return;
    }

    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token == null || token.isEmpty) {
      debugPrint('SignalRChat: No token — cannot connect');
      return;
    }

    _isStarting = true;
    final url = ApiConstants.chatHubUrl;
    debugPrint('SignalRChat: Connecting to $url');

    _connection = HubConnectionBuilder()
        .withUrl(
          url,
          options: HttpConnectionOptions(
            accessTokenFactory: () async =>
                await _storage.read(key: AppConstants.tokenKey) ?? token,
          ),
        )
        .withAutomaticReconnect()
        .build();

    // ─── Lắng nghe ReceiveMessage ─────────────────────────────────────────
    _connection!.on('ReceiveMessage', (arguments) {
      try {
        final raw = _normalize(arguments);
        if (raw.isEmpty) return;
        // currentUserId được xác định khi parse (isMine dựa vào senderId vs currentUserId)
        // Dùng senderId trực tiếp, ChatDetailPage sẽ set isMine sau khi nhận
        final msg = ChatMessageModel.fromSignalR(raw, '');
        _messageController.add(msg);
        debugPrint(
          'SignalRChat: ReceiveMessage [${msg.chatRoomId}] ${msg.senderName}: ${msg.content}',
        );
      } catch (e) {
        debugPrint('SignalRChat: Error parsing ReceiveMessage: $e');
      }
    });

    // ─── Lắng nghe UserTyping ─────────────────────────────────────────────
    _connection!.on('UserTyping', (arguments) {
      try {
        final raw = _normalize(arguments);
        if (raw.isEmpty) return;
        final event = TypingEventModel.fromJson(raw);
        _typingController.add(event);
      } catch (e) {
        debugPrint('SignalRChat: Error parsing UserTyping: $e');
      }
    });

    _connection!.on('UserPresenceChanged', (arguments) {
      try {
        final raw = _normalize(arguments);
        if (raw.isEmpty) return;
        final event = PresenceEventModel.fromJson(raw);
        _presenceController.add(event);
      } catch (e) {
        debugPrint('SignalRChat: Error parsing UserPresenceChanged: $e');
      }
    });

    // ─── Trạng thái connection ────────────────────────────────────────────
    _connection!.onclose(({Exception? error}) {
      debugPrint(
        'SignalRChat: Disconnected${error != null ? " — $error" : ""}',
      );
      _connectionStateController.add('Disconnected');
    });

    _connection!.onreconnecting(({Exception? error}) {
      debugPrint('SignalRChat: Reconnecting...');
      _connectionStateController.add('Reconnecting');
    });

    _connection!.onreconnected(({String? connectionId}) {
      debugPrint('SignalRChat: Reconnected ($connectionId)');
      _connectionStateController.add('Connected');
    });

    try {
      await _connection!.start();
      debugPrint('SignalRChat: Connected ✓');
      _connectionStateController.add('Connected');
    } catch (e) {
      debugPrint('SignalRChat: Connection failed: $e');
      _connectionStateController.add('Failed');
    } finally {
      _isStarting = false;
    }
  }

  // ─── JoinRoom ─────────────────────────────────────────────────────────────

  Future<void> joinRoom(String chatRoomId) async {
    if (_connection?.state != HubConnectionState.Connected) {
      await connect();
    }
    if (_connection?.state != HubConnectionState.Connected) return;
    try {
      await _connection!.invoke('JoinRoom', args: [chatRoomId]);
      debugPrint('SignalRChat: Joined room $chatRoomId');
    } catch (e) {
      debugPrint('SignalRChat: JoinRoom error: $e');
    }
  }

  // ─── SendMessage ──────────────────────────────────────────────────────────

  Future<void> sendMessage(
    String chatRoomId,
    String content, {
    String messageType = 'Text',
  }) async {
    if (_connection?.state != HubConnectionState.Connected) {
      await connect();
      await joinRoom(chatRoomId);
    }
    if (_connection?.state != HubConnectionState.Connected) {
      throw Exception('Không thể gửi tin nhắn: chưa kết nối chat server.');
    }
    if (content.trim().isEmpty) return;
    await _connection!.invoke(
      'SendMessage',
      args: [
        {
          'chatRoomId': chatRoomId,
          'content': content.trim(),
          'messageType': messageType,
        },
      ],
    );
    debugPrint('SignalRChat: SendMessage [$chatRoomId][$messageType] $content');
  }

  // ─── Typing ───────────────────────────────────────────────────────────────

  Future<void> sendTyping(String chatRoomId) async {
    if (_connection?.state != HubConnectionState.Connected) return;
    try {
      await _connection!.invoke('Typing', args: [chatRoomId]);
    } catch (_) {
      // Không log lỗi typing để tránh spam
    }
  }

  // ─── Disconnect ───────────────────────────────────────────────────────────

  Future<void> disconnect() async {
    await _connection?.stop();
    _connection = null;
    debugPrint('SignalRChat: Disconnected (manual)');
  }

  // ─── Dispose ──────────────────────────────────────────────────────────────

  void dispose() {
    _connection?.stop();
    _messageController.close();
    _typingController.close();
    _presenceController.close();
    _connectionStateController.close();
  }

  bool get isConnected => _connection?.state == HubConnectionState.Connected;

  // ─── Helper ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _normalize(List<Object?>? args) {
    if (args == null || args.isEmpty || args.first == null) return {};
    final first = args.first;
    if (first is Map<String, dynamic>) return first;
    if (first is Map) return Map<String, dynamic>.from(first);
    return {};
  }
}
