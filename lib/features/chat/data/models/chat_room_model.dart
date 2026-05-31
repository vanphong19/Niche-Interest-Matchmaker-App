// lib/features/chat/data/models/chat_room_model.dart
class ChatRoomModel {
  final String id;
  final String? matchId;   // null = Direct Message room (không gắn event)
  final String name;
  final String type; // 'Group' | 'Private'
  final DateTime createdAtUtc;
  final bool isActive;
  final int unreadCount;
  final ChatMessageModel? lastMessage;

  const ChatRoomModel({
    required this.id,
    this.matchId,
    required this.name,
    required this.type,
    required this.createdAtUtc,
    required this.isActive,
    this.unreadCount = 0,
    this.lastMessage,
  });

  bool get isGroup => type.toLowerCase() == 'group';
  bool get isDirect => matchId == null && type.toLowerCase() == 'private';

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['id'] as String? ?? '',
      matchId: json['matchId'] as String?,
      name: json['name'] as String? ?? 'Chat',
      type: json['type'] as String? ?? 'Group',
      createdAtUtc: json['createdAtUtc'] != null
          ? DateTime.tryParse(json['createdAtUtc'] as String) ?? DateTime.now()
          : DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
      unreadCount: json['unreadCount'] as int? ?? 0,
      lastMessage: json['lastMessage'] != null
          ? ChatMessageModel.fromJson(
              json['lastMessage'] as Map<String, dynamic>)
          : null,
    );
  }

  ChatRoomModel copyWith({int? unreadCount, ChatMessageModel? lastMessage}) {
    return ChatRoomModel(
      id: id,
      matchId: matchId,
      name: name,
      type: type,
      createdAtUtc: createdAtUtc,
      isActive: isActive,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}

class ChatMessageModel {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String content;
  final String messageType; // 'Text' | 'Image' | 'System'
  final DateTime createdAt;
  final bool isMine;
  final bool isDeleted;

  const ChatMessageModel({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.content,
    required this.messageType,
    required this.createdAt,
    required this.isMine,
    this.isDeleted = false,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json,
      {String? currentUserId}) {
    final senderId = json['senderId'] as String? ?? '';
    return ChatMessageModel(
      id: json['id'] as String? ?? '',
      chatRoomId: json['chatRoomId'] as String? ?? '',
      senderId: senderId,
      senderName: json['senderName'] as String? ?? 'User',
      senderAvatarUrl: json['senderAvatarUrl'] as String?,
      content: json['content'] as String? ?? '',
      messageType: json['messageType'] as String? ?? 'Text',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)?.toLocal() ??
              DateTime.now()
          : DateTime.now(),
      isMine: json['isMine'] as bool? ??
          (currentUserId != null &&
              senderId.toLowerCase() == currentUserId.toLowerCase()),
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  /// Build từ SignalR ReceiveMessage payload (không có isMine)
  factory ChatMessageModel.fromSignalR(
    Map<String, dynamic> json,
    String currentUserId,
  ) {
    final senderId = json['senderId'] as String? ?? '';
    return ChatMessageModel(
      id: json['id'] as String? ?? '',
      chatRoomId: json['chatRoomId'] as String? ?? '',
      senderId: senderId,
      senderName: json['senderName'] as String? ?? 'User',
      senderAvatarUrl: json['senderAvatarUrl'] as String?,
      content: json['content'] as String? ?? '',
      messageType: json['messageType'] as String? ?? 'Text',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)?.toLocal() ??
              DateTime.now()
          : DateTime.now(),
      isMine: senderId.toLowerCase() == currentUserId.toLowerCase(),
      isDeleted: false,
    );
  }
}

class TypingEventModel {
  final String chatRoomId;
  final String userId;
  final String userName;

  const TypingEventModel({
    required this.chatRoomId,
    required this.userId,
    required this.userName,
  });

  factory TypingEventModel.fromJson(Map<String, dynamic> json) {
    return TypingEventModel(
      chatRoomId: json['chatRoomId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? 'User',
    );
  }
}
