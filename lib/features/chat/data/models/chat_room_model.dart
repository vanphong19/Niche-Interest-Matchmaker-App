// lib/features/chat/data/models/chat_room_model.dart
class ChatRoomModel {
  final String id;
  final String? matchId; // null = Direct Message room (không gắn event)
  final String name;
  final String type; // 'Group' | 'Private'
  final DateTime createdAtUtc;
  final bool isActive;
  final int unreadCount;
  final ChatMessageModel? lastMessage;
  final String? otherUserId;
  final String? avatarUrl;
  final bool isOnline;

  const ChatRoomModel({
    required this.id,
    this.matchId,
    required this.name,
    required this.type,
    required this.createdAtUtc,
    required this.isActive,
    this.unreadCount = 0,
    this.lastMessage,
    this.otherUserId,
    this.avatarUrl,
    this.isOnline = false,
  });

  bool get isGroup => type.toLowerCase() == 'group';
  bool get isDirect => matchId == null && type.toLowerCase() == 'private';

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['id'] as String? ?? '',
      matchId: json['matchId'] as String?,
      name: json['name'] as String? ?? 'Chat',
      type: json['type'] as String? ?? 'Group',
      createdAtUtc: _parseUtcDateTime(json['createdAtUtc']).toUtc(),
      isActive: json['isActive'] as bool? ?? true,
      unreadCount: json['unreadCount'] as int? ?? 0,
      lastMessage: json['lastMessage'] != null
          ? ChatMessageModel.fromJson(
              json['lastMessage'] as Map<String, dynamic>,
            )
          : null,
      otherUserId:
          json['otherUserId'] as String? ?? json['OtherUserId'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? json['AvatarUrl'] as String?,
      isOnline: json['isOnline'] as bool? ?? json['IsOnline'] as bool? ?? false,
    );
  }

  ChatRoomModel copyWith({
    int? unreadCount,
    ChatMessageModel? lastMessage,
    bool? isOnline,
  }) {
    return ChatRoomModel(
      id: id,
      matchId: matchId,
      name: name,
      type: type,
      createdAtUtc: createdAtUtc,
      isActive: isActive,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessage: lastMessage ?? this.lastMessage,
      otherUserId: otherUserId,
      avatarUrl: avatarUrl,
      isOnline: isOnline ?? this.isOnline,
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

  factory ChatMessageModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final senderId = (json['senderId'] ?? json['SenderId'] ?? '').toString();
    return ChatMessageModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      chatRoomId: (json['chatRoomId'] ?? json['ChatRoomId'] ?? '').toString(),
      senderId: senderId,
      senderName: (json['senderName'] ?? json['SenderName'] ?? 'User')
          .toString(),
      senderAvatarUrl:
          json['senderAvatarUrl'] as String? ??
          json['SenderAvatarUrl'] as String?,
      content: (json['content'] ?? json['Content'] ?? '').toString(),
      messageType: (json['messageType'] ?? json['MessageType'] ?? 'Text')
          .toString(),
      createdAt: _parseUtcDateTime(
        json['createdAt'] ??
            json['CreatedAt'] ??
            json['createdAtUtc'] ??
            json['CreatedAtUtc'],
      ),
      isMine:
          json['isMine'] as bool? ??
          (currentUserId != null &&
              senderId.toLowerCase() == currentUserId.toLowerCase()),
      isDeleted:
          json['isDeleted'] as bool? ?? json['IsDeleted'] as bool? ?? false,
    );
  }

  /// Build từ SignalR ReceiveMessage payload (không có isMine)
  factory ChatMessageModel.fromSignalR(
    Map<String, dynamic> json,
    String currentUserId,
  ) {
    final senderId = (json['senderId'] ?? json['SenderId'] ?? '').toString();
    return ChatMessageModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      chatRoomId: (json['chatRoomId'] ?? json['ChatRoomId'] ?? '').toString(),
      senderId: senderId,
      senderName: (json['senderName'] ?? json['SenderName'] ?? 'User')
          .toString(),
      senderAvatarUrl:
          json['senderAvatarUrl'] as String? ??
          json['SenderAvatarUrl'] as String?,
      content: (json['content'] ?? json['Content'] ?? '').toString(),
      messageType: (json['messageType'] ?? json['MessageType'] ?? 'Text')
          .toString(),
      createdAt: _parseUtcDateTime(
        json['createdAt'] ??
            json['CreatedAt'] ??
            json['createdAtUtc'] ??
            json['CreatedAtUtc'],
      ),
      isMine: senderId.toLowerCase() == currentUserId.toLowerCase(),
      isDeleted: false,
    );
  }
}

DateTime _parseUtcDateTime(Object? value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) {
    return (value.isUtc
            ? value
            : DateTime.utc(
                value.year,
                value.month,
                value.day,
                value.hour,
                value.minute,
                value.second,
                value.millisecond,
                value.microsecond,
              ))
        .toLocal();
  }

  final raw = value.toString().trim();
  if (raw.isEmpty) return DateTime.now();

  final hasTimezone = RegExp(
    r'(z|[+-]\d{2}:?\d{2})$',
    caseSensitive: false,
  ).hasMatch(raw);
  final normalized = hasTimezone ? raw : '${raw}Z';
  return DateTime.tryParse(normalized)?.toLocal() ?? DateTime.now();
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

class PresenceEventModel {
  final String chatRoomId;
  final String userId;
  final bool isOnline;

  const PresenceEventModel({
    required this.chatRoomId,
    required this.userId,
    required this.isOnline,
  });

  factory PresenceEventModel.fromJson(Map<String, dynamic> json) {
    return PresenceEventModel(
      chatRoomId: (json['chatRoomId'] ?? json['ChatRoomId'] ?? '').toString(),
      userId: (json['userId'] ?? json['UserId'] ?? '').toString(),
      isOnline: json['isOnline'] as bool? ?? json['IsOnline'] as bool? ?? false,
    );
  }
}
