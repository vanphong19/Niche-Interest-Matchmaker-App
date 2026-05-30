// lib/features/chat/domain/entities/chat_conversation.dart

enum ConversationType { groupChat, directMessage }

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.type,
    required this.title,
    this.avatarUrl,
    this.eventId,
    this.eventEmoji,
    required this.participantIds,
    required this.participantNames,
    this.participantAvatars = const [],
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastMessageSenderName,
    this.unreadCount = 0,
    this.isOnline = false,
  });

  final String id;
  final ConversationType type;
  final String title;
  final String? avatarUrl;

  // Group chat extras
  final String? eventId;
  final String? eventEmoji;

  // Participants
  final List<String> participantIds;
  final List<String> participantNames;
  final List<String> participantAvatars;

  // Last message preview
  final String lastMessage;
  final DateTime lastMessageAt;
  final String lastMessageSenderName;

  final int unreadCount;
  final bool isOnline; // for DMs
}

// ─── Mock Data ────────────────────────────────────────────────────────────────

final class ChatMockData {
  ChatMockData._();

  static const _currentUserId = 'me-123';
  static const _currentUserName = 'Bạn';

  static String get currentUserId => _currentUserId;

  /// Sample mock conversations for inbox
  static List<ChatConversation> get mockConversations => [
        ChatConversation(
          id: 'grp-001',
          type: ConversationType.groupChat,
          title: 'Hiking Núi Bà Đen Weekend',
          eventId: 'evt-001',
          eventEmoji: '🏔️',
          participantIds: const ['me-123', 'u2', 'u3', 'u4', 'u5'],
          participantNames: const ['Bạn', 'Minh Anh', 'Quốc Bảo', 'Lan Phương', 'Đức Thịnh'],
          participantAvatars: const [],
          lastMessage: 'Mọi người đừng quên mang đủ nước nhé! 💧',
          lastMessageAt: _minutesAgo(5),
          lastMessageSenderName: 'Minh Anh',
          unreadCount: 3,
        ),
        ChatConversation(
          id: 'grp-002',
          type: ConversationType.groupChat,
          title: 'Cafe Hopping Q1 Chủ Nhật',
          eventId: 'evt-002',
          eventEmoji: '☕',
          participantIds: const ['me-123', 'u2', 'u6'],
          participantNames: const ['Bạn', 'Minh Anh', 'Thu Hà'],
          participantAvatars: const [],
          lastMessage: 'Ok mình sẽ đặt bàn trước 2 tiếng nha',
          lastMessageAt: _minutesAgo(42),
          lastMessageSenderName: 'Bạn',
          unreadCount: 0,
        ),
        ChatConversation(
          id: 'dm-001',
          type: ConversationType.directMessage,
          title: 'Minh Anh',
          participantIds: const ['me-123', 'u2'],
          participantNames: const ['Bạn', 'Minh Anh'],
          participantAvatars: const [],
          lastMessage: 'Bạn có tham gia buổi leo núi cuối tuần không?',
          lastMessageAt: _minutesAgo(18),
          lastMessageSenderName: 'Minh Anh',
          unreadCount: 1,
          isOnline: true,
        ),
        ChatConversation(
          id: 'grp-003',
          type: ConversationType.groupChat,
          title: 'Chạy Bộ Sáng – Công viên Gia Định',
          eventId: 'evt-003',
          eventEmoji: '🏃',
          participantIds: const ['me-123', 'u3', 'u4', 'u7', 'u8', 'u9'],
          participantNames: const ['Bạn', 'Quốc Bảo', 'Lan Phương', 'Hải Nam', 'Yến Nhi', 'Tùng Lâm'],
          participantAvatars: const [],
          lastMessage: '6h sáng nha mọi người, đừng ngủ quên 😄',
          lastMessageAt: _hoursAgo(2),
          lastMessageSenderName: 'Quốc Bảo',
          unreadCount: 7,
        ),
        ChatConversation(
          id: 'dm-002',
          type: ConversationType.directMessage,
          title: 'Quốc Bảo',
          participantIds: const ['me-123', 'u3'],
          participantNames: const ['Bạn', 'Quốc Bảo'],
          participantAvatars: const [],
          lastMessage: 'Cảm ơn bạn đã tham gia nhé! 🙌',
          lastMessageAt: _hoursAgo(5),
          lastMessageSenderName: 'Bạn',
          unreadCount: 0,
          isOnline: false,
        ),
      ];

  /// Sample mock messages for a group chat
  static List<MockMember> get mockMembers => const [
        MockMember(id: 'u2', name: 'Minh Anh', isOnline: true),
        MockMember(id: 'u3', name: 'Quốc Bảo', isOnline: false),
        MockMember(id: 'u4', name: 'Lan Phương', isOnline: true),
        MockMember(id: 'u5', name: 'Đức Thịnh', isOnline: false),
        MockMember(id: 'u6', name: 'Thu Hà', isOnline: true),
      ];

  static List<ChatMockMessage> get mockGroupMessages => [
        ChatMockMessage(
          id: 'm1',
          senderId: 'u2',
          senderName: 'Minh Anh',
          content: 'Mọi người ơi, cuối tuần này leo núi nha! 🏔️',
          minutesAgo: 60,
        ),
        ChatMockMessage(
          id: 'm2',
          senderId: 'u3',
          senderName: 'Quốc Bảo',
          content: 'Tuyệt vời! Mình đã chuẩn bị xong rồi 💪',
          minutesAgo: 55,
        ),
        ChatMockMessage(
          id: 'm3',
          senderId: _currentUserId,
          senderName: _currentUserName,
          content: 'Mình cũng vậy! Hẹn gặp mọi người ở điểm xuất phát nhé',
          minutesAgo: 50,
        ),
        ChatMockMessage(
          id: 'm4',
          senderId: 'u4',
          senderName: 'Lan Phương',
          content: 'Bọn mình nên đi xe gì đến đó? Ai có ô tô không?',
          minutesAgo: 45,
        ),
        ChatMockMessage(
          id: 'm5',
          senderId: _currentUserId,
          senderName: _currentUserName,
          content: 'Mình có thể chở được 3 người, ai cần thì báo mình nhé 🚗',
          minutesAgo: 40,
        ),
        ChatMockMessage(
          id: 'm6',
          senderId: 'u3',
          senderName: 'Quốc Bảo',
          content: 'Cho mình với! Cảm ơn bạn nhiều',
          minutesAgo: 38,
        ),
        ChatMockMessage(
          id: 'm7',
          senderId: 'u2',
          senderName: 'Minh Anh',
          content: 'Mọi người đừng quên mang đủ nước nhé! 💧',
          minutesAgo: 5,
        ),
      ];

  static List<ChatMockMessage> get mockDmMessages => [
        ChatMockMessage(
          id: 'd1',
          senderId: 'u2',
          senderName: 'Minh Anh',
          content: 'Hey! Bạn có tham gia buổi leo núi cuối tuần không?',
          minutesAgo: 30,
        ),
        ChatMockMessage(
          id: 'd2',
          senderId: _currentUserId,
          senderName: _currentUserName,
          content: 'Có chứ! Mình đã đăng ký rồi 😊',
          minutesAgo: 25,
        ),
        ChatMockMessage(
          id: 'd3',
          senderId: 'u2',
          senderName: 'Minh Anh',
          content: 'Tuyệt! Mình sẽ chia sẻ bản đồ đường đi nhé',
          minutesAgo: 22,
        ),
        ChatMockMessage(
          id: 'd4',
          senderId: _currentUserId,
          senderName: _currentUserName,
          content: 'Ok, cảm ơn bạn! 🙏',
          minutesAgo: 20,
        ),
        ChatMockMessage(
          id: 'd5',
          senderId: 'u2',
          senderName: 'Minh Anh',
          content: 'Bạn có tham gia buổi leo núi cuối tuần không?',
          minutesAgo: 18,
        ),
      ];

  // ─── Helpers ────────────────────────────────────────────────────────────────

  static DateTime _minutesAgo(int minutes) =>
      DateTime.now().subtract(Duration(minutes: minutes));

  static DateTime _hoursAgo(int hours) =>
      DateTime.now().subtract(Duration(hours: hours));
}

class MockMember {
  const MockMember({
    required this.id,
    required this.name,
    required this.isOnline,
    this.avatarUrl,
  });
  final String id;
  final String name;
  final bool isOnline;
  final String? avatarUrl;
}

class ChatMockMessage {
  ChatMockMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required int minutesAgo,
    this.senderAvatar,
  }) : timestamp = DateTime.now().subtract(Duration(minutes: minutesAgo));

  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final DateTime timestamp;
}
