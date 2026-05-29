// lib/features/chat/presentation/pages/event_group_chat_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../domain/entities/chat_conversation.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_bubble.dart';
import 'dm_conversation_page.dart';

class EventGroupChatPage extends StatefulWidget {
  const EventGroupChatPage({
    super.key,
    required this.eventId,
    required this.eventTitle,
    required this.eventEmoji,
    required this.members,
  });

  final String eventId;
  final String eventTitle;
  final String eventEmoji;
  final List<MockMember> members;

  @override
  State<EventGroupChatPage> createState() => _EventGroupChatPageState();
}

class _EventGroupChatPageState extends State<EventGroupChatPage>
    with SingleTickerProviderStateMixin {
  late final List<ChatMockMessage> _messages;
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _appearCtrl;
  Timer? _simulateTimer;

  final _currentUserId = ChatMockData.currentUserId;

  // Simulated incoming messages
  final _incomingPool = [
    'Mọi người tập hợp đúng giờ nhé! 🕐',
    'Ai cần bản đồ đường đi không? 🗺️',
    'Thời tiết hôm nay đẹp lắm 🌤️',
    'Nhớ mang theo kem chống nắng nha!',
    '👍',
    'Tuyệt vời! Mình rất háo hức 🎉',
    'Đường đi có khó không mọi người?',
  ];
  int _incomingIndex = 0;

  @override
  void initState() {
    super.initState();
    _messages = List.from(ChatMockData.mockGroupMessages);
    _appearCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    // Simulate a message after 4 seconds
    _simulateTimer = Timer(const Duration(seconds: 4), _simulateIncoming);
  }

  @override
  void dispose() {
    _simulateTimer?.cancel();
    _scrollController.dispose();
    _appearCtrl.dispose();
    super.dispose();
  }

  void _simulateIncoming() {
    if (!mounted) return;
    final member =
        widget.members[_incomingIndex % widget.members.length];
    final text = _incomingPool[_incomingIndex % _incomingPool.length];
    setState(() {
      _messages.add(
        ChatMockMessage(
          id: 'sim-$_incomingIndex',
          senderId: member.id,
          senderName: member.name,
          content: text,
          minutesAgo: 0,
        ),
      );
      _incomingIndex++;
    });
    _scrollToBottom();

    // Schedule next
    _simulateTimer = Timer(
      Duration(seconds: 5 + (_incomingIndex * 2) % 6),
      _simulateIncoming,
    );
  }

  void _sendMessage(String text) {
    HapticFeedback.selectionClick();
    setState(() {
      _messages.add(
        ChatMockMessage(
          id: 'my-${DateTime.now().millisecondsSinceEpoch}',
          senderId: _currentUserId,
          senderName: 'Bạn',
          content: text,
          minutesAgo: 0,
        ),
      );
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _openMembersSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MembersSheet(
        members: widget.members,
        onMessageMember: (member) {
          Navigator.pop(context);
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DmConversationPage(
                userId: member.id,
                userName: member.name,
                isOnline: member.isOnline,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBgPrimary : const Color(0xFFF5F7FF),
      body: Column(
        children: [
          _buildAppBar(isDark),
          Expanded(child: _buildMessageList(isDark)),
          ChatInputBar(onSend: _sendMessage),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        left: 8,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.darkBorderLight
                : AppColors.borderLight,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? AppColors.darkTextPrimary : AppColors.secondary,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),

          // Event emoji
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: Text(
                widget.eventEmoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title + member count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.eventTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.members.length + 1} thành viên',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Member avatars stack
          GestureDetector(
            onTap: _openMembersSheet,
            child: SizedBox(
              width: (widget.members.take(3).length * 22 + 14).toDouble(),
              height: 36,
              child: Stack(
                children: [
                  ...widget.members.take(3).toList().asMap().entries.map((e) {
                    return Positioned(
                      left: e.key * 22.0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBgSecondary
                                : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: VibeAvatar(
                          name: e.value.name,
                          size: 32,
                          showOnlineIndicator: e.value.isOnline,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Members button
          GestureDetector(
            onTap: _openMembersSheet,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group_rounded,
                      color: AppColors.primary, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Members',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isMine = msg.senderId == _currentUserId;
        final isFirst = index == 0 ||
            _messages[index - 1].senderId != msg.senderId;
        final isLast = index == _messages.length - 1 ||
            _messages[index + 1].senderId != msg.senderId;

        // Add date separator if needed
        final Widget? dateSep = _buildDateSeparator(index);

        return Column(
          children: [
            if (dateSep != null) dateSep,
            Padding(
              padding: EdgeInsets.only(
                top: isFirst ? 8 : 2,
                bottom: isLast ? 8 : 2,
              ),
              child: ChatMessageBubble(
                message: msg,
                isMine: isMine,
                showAvatar: !isMine && isLast,
                showSenderName: !isMine && isFirst,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget? _buildDateSeparator(int index) {
    final msg = _messages[index];
    if (index == 0) {
      return _DateSeparator(date: msg.timestamp);
    }
    final prev = _messages[index - 1];
    final sameDay = msg.timestamp.day == prev.timestamp.day &&
        msg.timestamp.month == prev.timestamp.month &&
        msg.timestamp.year == prev.timestamp.year;
    if (!sameDay) {
      return _DateSeparator(date: msg.timestamp);
    }
    return null;
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});
  final DateTime date;

  String _format(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return 'Hôm nay';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.borderLight)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _format(date),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.borderLight)),
        ],
      ),
    );
  }
}

// ─── Members Sheet ────────────────────────────────────────────────────────────

class _MembersSheet extends StatelessWidget {
  const _MembersSheet({
    required this.members,
    required this.onMessageMember,
  });

  final List<MockMember> members;
  final void Function(MockMember) onMessageMember;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderMedium,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.group_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thành viên nhóm',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.secondary,
                      ),
                    ),
                    Text(
                      '${members.length + 1} người',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.borderLight),

          // Members list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: members.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              indent: 72,
              color: AppColors.borderLight,
            ),
            itemBuilder: (_, i) {
              final member = members[i];
              return _MemberRow(
                member: member,
                onMessage: () => onMessageMember(member),
              );
            },
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.onMessage});
  final MockMember member;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          VibeAvatar(
            name: member.name,
            imageUrl: member.avatarUrl,
            size: 44,
            showOnlineIndicator: member.isOnline,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.secondary,
                  ),
                ),
                Text(
                  member.isOnline ? 'Đang hoạt động' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: member.isOnline
                        ? AppColors.success
                        : AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onMessage();
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      color: AppColors.primary, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Nhắn tin',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
