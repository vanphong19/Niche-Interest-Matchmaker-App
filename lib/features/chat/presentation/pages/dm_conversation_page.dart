// lib/features/chat/presentation/pages/dm_conversation_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../domain/entities/chat_conversation.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_bubble.dart';

class DmConversationPage extends StatefulWidget {
  const DmConversationPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.isOnline,
    this.userAvatarUrl,
  });

  final String userId;
  final String userName;
  final bool isOnline;
  final String? userAvatarUrl;

  @override
  State<DmConversationPage> createState() => _DmConversationPageState();
}

class _DmConversationPageState extends State<DmConversationPage> {
  late final List<ChatMockMessage> _messages;
  final ScrollController _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _isTyping = false;

  final _currentUserId = ChatMockData.currentUserId;

  @override
  void initState() {
    super.initState();
    _messages = List.from(ChatMockData.mockDmMessages);

    // Simulate "typing" after 3 seconds
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _isTyping = true);
      Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() {
          _isTyping = false;
          _messages.add(
            ChatMockMessage(
              id: 'dm-sim-1',
              senderId: widget.userId,
              senderName: widget.userName,
              content: 'Ừ, mình cũng đang háo hức lắm! 🎉',
              minutesAgo: 0,
            ),
          );
        });
        _scrollToBottom();
      });
    });

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToBottom(animated: false));
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
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

    // Simulate reply after 2-4 seconds
    final delay = Duration(seconds: 2 + (_messages.length % 3));
    Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _isTyping = true);
      Timer(delay, () {
        if (!mounted) return;
        final replies = [
          'Được thôi! 👍',
          'Cảm ơn bạn nhé!',
          'Ok mình hiểu rồi 😊',
          'Tuyệt! Hẹn gặp nhau nhé 🤝',
          'Mình sẽ nhớ đấy!',
        ];
        final reply =
            replies[_messages.length % replies.length];
        setState(() {
          _isTyping = false;
          _messages.add(
            ChatMockMessage(
              id: 'reply-${DateTime.now().millisecondsSinceEpoch}',
              senderId: widget.userId,
              senderName: widget.userName,
              content: reply,
              minutesAgo: 0,
            ),
          );
        });
        _scrollToBottom();
      });
    });
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (animated) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    });
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
          if (_isTyping) _buildTypingIndicator(isDark),
          ChatInputBar(
            onSend: _sendMessage,
            hintText: 'Nhắn tin cho ${widget.userName}...',
          ),
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
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? AppColors.darkTextPrimary : AppColors.secondary,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          VibeAvatar(
            name: widget.userName,
            imageUrl: widget.userAvatarUrl,
            size: 42,
            showOnlineIndicator: widget.isOnline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.userName,
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
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: widget.isOnline
                            ? AppColors.success
                            : AppColors.textHint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      widget.isOnline ? 'Đang hoạt động' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isOnline
                            ? AppColors.success
                            : AppColors.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // More actions
          IconButton(
            icon: Icon(
              Icons.more_vert_rounded,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textHint,
            ),
            onPressed: () {},
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

        return Padding(
          padding: EdgeInsets.only(
            top: isFirst ? 8 : 2,
            bottom: isLast ? 8 : 2,
          ),
          child: ChatMessageBubble(
            message: msg,
            isMine: isMine,
            showAvatar: !isMine && isLast,
            showSenderName: false, // DMs don't need sender name
          ),
        );
      },
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        children: [
          VibeAvatar(
            name: widget.userName,
            size: 28,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final t = (_ctrl.value + delay) % 1.0;
            final opacity = t < 0.5 ? t * 2 : (1 - t) * 2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: AppColors.textHint.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
