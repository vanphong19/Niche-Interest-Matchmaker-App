// lib/features/chat/presentation/cubit/chat_cubit.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/signalr_service.dart';
import '../../../../core/utils/profile_state.dart';
import '../../../../injection/injection_container.dart';
import '../../data/models/chat_room_model.dart';
import '../../data/services/chat_api_service.dart';
import '../../data/services/signalr_chat_service.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatApiService _api;
  final SignalRChatService _signalR;

  StreamSubscription<ChatMessageModel>? _messageSub;
  StreamSubscription<TypingEventModel>? _typingSub;
  Timer? _typingClearTimer;

  String? _currentRoomId;

  ChatCubit(this._api, this._signalR) : super(ChatInitial());

  String get _currentUserId => ProfileState.notifier.value.id;

  // ─── Lấy danh sách phòng chat của event ──────────────────────────────────

  Future<void> loadChatRooms(String eventId) async {
    emit(ChatLoading());
    try {
      final rooms = await _api.getChatRoomsByEvent(eventId);
      emit(ChatRoomsLoaded(rooms));
    } catch (e) {
      emit(ChatError(_friendlyError(e)));
    }
  }

  // ─── Mở room: load messages + kết nối SignalR ────────────────────────────

  Future<void> openChatRoom(ChatRoomModel room) async {
    emit(ChatRoomOpening());
    _currentRoomId = room.id;

    // 1. Load lịch sử
    final messages = await _api.getMessages(
      room.id,
      currentUserId: _currentUserId,
    );

    emit(ChatMessagesLoaded(room: room, messages: messages));

    // 2. Kết nối SignalR nếu chưa
    await _signalR.connect();

    // 3. Join room
    await _signalR.joinRoom(room.id);

    // 4. Đăng ký stream nhận tin nhắn
    await _messageSub?.cancel();
    _messageSub = _signalR.onMessageReceived.listen(_onMessageReceived);

    // 5. Đăng ký stream typing
    await _typingSub?.cancel();
    _typingSub = _signalR.onUserTyping.listen(_onUserTyping);

    // 6. Mark as read

    await _markRoomRead(room.id);
  }

  // ─── Gửi tin nhắn ────────────────────────────────────────────────────────

  Future<void> sendMessage(
    String content, {
    String messageType = 'Text',
  }) async {
    final s = state;
    if (s is! ChatMessagesLoaded) return;
    if (content.trim().isEmpty) return;

    emit(s.copyWith(isSending: true));
    try {
      await _signalR.sendMessage(s.room.id, content, messageType: messageType);
      // Tin nhắn sẽ được append khi nhận ReceiveMessage từ hub
    } catch (e) {
      emit(s.copyWith(isSending: false));
      rethrow;
    }
  }

  // ─── Gửi typing (debounce từ UI) ─────────────────────────────────────────

  Future<void> sendTyping() async {
    final s = state;
    if (s is! ChatMessagesLoaded) return;
    await _signalR.sendTyping(s.room.id);
  }

  // ─── Xử lý ReceiveMessage từ SignalR ─────────────────────────────────────

  void _onMessageReceived(ChatMessageModel rawMsg) {
    final s = state;
    if (s is! ChatMessagesLoaded) return;
    if (rawMsg.chatRoomId != _currentRoomId) return; // không phải phòng này

    // Tính isMine dựa vào currentUserId thực
    final isMine =
        rawMsg.senderId.toLowerCase() == _currentUserId.toLowerCase();
    final msg = ChatMessageModel(
      id: rawMsg.id,
      chatRoomId: rawMsg.chatRoomId,
      senderId: rawMsg.senderId,
      senderName: rawMsg.senderName,
      senderAvatarUrl: rawMsg.senderAvatarUrl,
      content: rawMsg.content,
      messageType: rawMsg.messageType,
      createdAt: rawMsg.createdAt,
      isMine: isMine,
    );

    // Tránh duplicate
    final exists = s.messages.any((m) => m.id == msg.id);
    if (exists) return;

    final updated = [...s.messages, msg];
    emit(s.copyWith(messages: updated, isSending: false));

    // Mark as read khi đang trong room

    unawaited(_markRoomRead(s.room.id));
    debugPrint('ChatCubit: New message from ${msg.senderName}');
  }

  // ─── Xử lý UserTyping ────────────────────────────────────────────────────

  Future<void> _markRoomRead(String roomId) async {
    await _api.markAsRead(roomId);
    sl<SignalRService>().emitLocalChange('chat', {'roomId': roomId});
  }

  void _onUserTyping(TypingEventModel event) {
    final s = state;
    if (s is! ChatMessagesLoaded) return;
    if (event.chatRoomId != _currentRoomId) return;
    if (event.userId.toLowerCase() == _currentUserId.toLowerCase()) return;

    final names = List<String>.from(s.typingUserNames);
    if (!names.contains(event.userName)) names.add(event.userName);
    emit(s.copyWith(typingUserNames: names));

    // Tự ẩn sau 3 giây
    _typingClearTimer?.cancel();
    _typingClearTimer = Timer(const Duration(seconds: 3), () {
      final cur = state;
      if (cur is ChatMessagesLoaded) {
        final cleared = List<String>.from(cur.typingUserNames)
          ..remove(event.userName);
        emit(cur.copyWith(typingUserNames: cleared));
      }
    });
  }

  // ─── Close / cleanup ─────────────────────────────────────────────────────

  @override
  Future<void> close() async {
    await _messageSub?.cancel();
    await _typingSub?.cancel();
    _typingClearTimer?.cancel();
    await super.close();
  }

  // ─── Helper ───────────────────────────────────────────────────────────────

  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('403') || msg.contains('access denied')) {
      return 'Bạn không có quyền truy cập phòng chat này.';
    }
    if (msg.contains('401') || msg.contains('unauthorized')) {
      return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return 'Không thể kết nối. Kiểm tra internet và thử lại.';
    }
    if (msg.contains('404') || msg.contains('not found')) {
      return 'Không tìm thấy phòng chat.';
    }
    return 'Không thể tải chat. Thử lại sau.';
  }
}
