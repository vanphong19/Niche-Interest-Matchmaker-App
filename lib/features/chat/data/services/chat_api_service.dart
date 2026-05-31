// lib/features/chat/data/services/chat_api_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/chat_room_model.dart';

class ChatApiService {
  final Dio _dio;

  ChatApiService(Dio dio) : _dio = dio;

  // ─── Unwrap { success, data } từ ResponseWrapperMiddleware ────────────────

  dynamic _unwrap(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('data')) return responseData['data'];
      if (responseData.containsKey('Data')) return responseData['Data'];
    }
    return responseData;
  }

  // ─── GET /api/events/{eventId}/chat-rooms ─────────────────────────────────

  Future<List<ChatRoomModel>> getChatRoomsByEvent(String eventId) async {
    try {
      final response = await _dio.get('/api/events/$eventId/chat-rooms');
      final unwrapped = _unwrap(response.data);
      debugPrint('ChatApiService.getChatRoomsByEvent: $unwrapped');
      if (unwrapped is List) {
        return unwrapped
            .map((e) => ChatRoomModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('getChatRoomsByEvent error: ${e.response?.statusCode} ${e.response?.data}');
      rethrow;
    }
  }

  // ─── POST /api/events/{eventId}/chat-room ─────────────────────────────────

  Future<ChatRoomModel> createGroupChatRoom(String eventId,
      {String? name}) async {
    try {
      final response = await _dio.post(
        '/api/events/$eventId/chat-room',
        data: {'name': name ?? 'Nhóm chat sự kiện'},
      );
      final unwrapped = _unwrap(response.data);
      debugPrint('ChatApiService.createGroupChatRoom: $unwrapped');
      return ChatRoomModel.fromJson(unwrapped as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('createGroupChatRoom error: ${e.response?.statusCode} ${e.response?.data}');
      rethrow;
    }
  }

  // ─── POST /api/events/{eventId}/private-chat ─────────────────────────────

  Future<ChatRoomModel> getOrCreatePrivateChat(
    String eventId,
    String targetUserId,
  ) async {
    try {
      final response = await _dio.post(
        '/api/events/$eventId/private-chat',
        data: {'targetUserId': targetUserId},
      );
      final unwrapped = _unwrap(response.data);
      return ChatRoomModel.fromJson(unwrapped as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('getOrCreatePrivateChat error: ${e.response?.statusCode} ${e.response?.data}');
      rethrow;
    }
  }

  // ─── GET /api/chat-rooms/{chatRoomId}/messages ────────────────────────────

  Future<List<ChatMessageModel>> getMessages(
    String chatRoomId, {
    int page = 1,
    int pageSize = 30,
    String? currentUserId,
  }) async {
    try {
      final response = await _dio.get(
        '/api/chat-rooms/$chatRoomId/messages',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );

      final unwrapped = _unwrap(response.data);
      debugPrint('ChatApiService.getMessages unwrapped type: ${unwrapped.runtimeType}');

      List<dynamic> items;

      // Có thể là paged object { items, totalCount } hoặc array thẳng
      if (unwrapped is Map<String, dynamic>) {
        items = (unwrapped['items'] ?? unwrapped['Items'] ?? []) as List<dynamic>;
      } else if (unwrapped is List) {
        items = unwrapped;
      } else {
        debugPrint('ChatApiService.getMessages: unexpected format $unwrapped');
        return [];
      }

      return items
          .map((e) => ChatMessageModel.fromJson(
                e as Map<String, dynamic>,
                currentUserId: currentUserId,
              ))
          .toList();
    } on DioException catch (e) {
      debugPrint('getMessages error: ${e.response?.statusCode} ${e.response?.data}');
      rethrow;
    }
  }

  // ─── POST /api/users/{targetUserId}/direct-message ───────────────────────

  Future<ChatRoomModel> openDirectMessage(String targetUserId) async {
    try {
      final response = await _dio.post('/api/users/$targetUserId/direct-message');
      final unwrapped = _unwrap(response.data);
      debugPrint('ChatApiService.openDirectMessage: $unwrapped');
      return ChatRoomModel.fromJson(unwrapped as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('openDirectMessage error: ${e.response?.statusCode} ${e.response?.data}');
      rethrow;
    }
  }

  // ─── POST /api/chat-rooms/{chatRoomId}/read ───────────────────────────────

  Future<void> markAsRead(String chatRoomId) async {
    try {
      await _dio.post('/api/chat-rooms/$chatRoomId/read');
    } catch (e) {
      // Lỗi mark-read không critical
      debugPrint('markAsRead ignored: $e');
    }
  }
}
