// lib/features/chat/presentation/pages/chat_detail_page.dart
//
// ChatDetailPage — Kết nối backend thật (API + SignalR)
// Được điều hướng từ EventDetailPage
//
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../injection/injection_container.dart';
import '../../data/models/chat_room_model.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';

class ChatDetailPage extends StatefulWidget {
  const ChatDetailPage({
    super.key,
    required this.room,
  });

  final ChatRoomModel room;

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  late final ChatCubit _cubit;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _typingDebounce;
  bool _isSendButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _cubit = sl<ChatCubit>();
    _cubit.openChatRoom(widget.room);

    _inputController.addListener(() {
      final hasText = _inputController.text.trim().isNotEmpty;
      if (hasText != _isSendButtonEnabled) {
        setState(() => _isSendButtonEnabled = hasText);
      }
    });
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _inputController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
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

  Future<void> _handleSend() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.selectionClick();
    _inputController.clear();
    setState(() => _isSendButtonEnabled = false);

    try {
      await _cubit.sendMessage(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gửi thất bại: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleTyping(String _) {
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 500), () {
      _cubit.sendTyping();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBgPrimary : const Color(0xFFF5F7FF),
        body: BlocConsumer<ChatCubit, ChatState>(
          listenWhen: (prev, curr) => curr is ChatMessagesLoaded,
          listener: (context, state) {
            if (state is ChatMessagesLoaded) {
              _scrollToBottom();
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                _buildAppBar(isDark),
                Expanded(child: _buildBody(state, isDark)),
                _buildInput(isDark, state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        left: 4,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorderLight : AppColors.borderLight,
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
          // Icon phòng chat
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: widget.room.isGroup
                  ? AppColors.primaryGradient
                  : const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: Icon(
                widget.room.isGroup
                    ? Icons.group_rounded
                    : Icons.person_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.room.name,
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
                Text(
                  widget.room.isGroup ? 'Nhóm chat sự kiện' : 'Tin nhắn riêng',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ChatState state, bool isDark) {
    if (state is ChatLoading || state is ChatRoomOpening || state is ChatInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ChatError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _cubit.openChatRoom(widget.room),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is ChatMessagesLoaded) {
      final messages = state.messages;

      return Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _buildEmpty(isDark)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 16),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final msg = messages[i];
                      final showSender = !msg.isMine &&
                          (i == 0 ||
                              messages[i - 1].senderId != msg.senderId);
                      final showAvatar = !msg.isMine &&
                          (i == messages.length - 1 ||
                              messages[i + 1].senderId != msg.senderId);
                      final isFirst = i == 0 ||
                          messages[i - 1].senderId != msg.senderId;
                      final isLast = i == messages.length - 1 ||
                          messages[i + 1].senderId != msg.senderId;

                      return Column(
                        children: [
                          if (_showDateSep(messages, i))
                            _DateSep(date: msg.createdAt),
                          Padding(
                            padding: EdgeInsets.only(
                              top: isFirst ? 6 : 2,
                              bottom: isLast ? 6 : 2,
                            ),
                            child: _MessageBubble(
                              message: msg,
                              showSenderName: showSender,
                              showAvatar: showAvatar,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // Typing indicator
          if (state.typingUserNames.isNotEmpty)
            _buildTypingIndicator(state.typingUserNames, isDark),
        ],
      );
    }

    return const SizedBox();
  }

  bool _showDateSep(List<ChatMessageModel> messages, int i) {
    if (i == 0) return true;
    final cur = messages[i].createdAt;
    final prev = messages[i - 1].createdAt;
    return cur.day != prev.day ||
        cur.month != prev.month ||
        cur.year != prev.year;
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có tin nhắn nào',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.secondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy gửi tin nhắn đầu tiên!',
            style: TextStyle(fontSize: 13, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(List<String> names, bool isDark) {
    final label = names.length == 1
        ? '${names[0]} đang nhập...'
        : '${names.join(', ')} đang nhập...';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBgSecondary : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(bool isDark, ChatState state) {
    final isSending = state is ChatMessagesLoaded && state.isSending;
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorderLight : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBgTertiary : AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorderLight
                      : AppColors.borderLight,
                ),
              ),
              child: TextField(
                controller: _inputController,
                focusNode: _focusNode,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                onChanged: _handleTyping,
                enabled: !isSending,
                decoration: const InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle:
                      TextStyle(color: AppColors.textHint, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                style: TextStyle(
                  fontSize: 15,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: (isSending || !_isSendButtonEnabled) ? null : _handleSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: (_isSendButtonEnabled && !isSending)
                    ? AppColors.primaryGradient
                    : null,
                color: (_isSendButtonEnabled && !isSending)
                    ? null
                    : AppColors.bgSecondary,
                shape: BoxShape.circle,
                boxShadow: (_isSendButtonEnabled && !isSending)
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: isSending
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.send_rounded,
                      color: _isSendButtonEnabled ? Colors.white : AppColors.textHint,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.showSenderName,
    required this.showAvatar,
  });

  final ChatMessageModel message;
  final bool showSenderName;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMine = message.isMine;
    final timeStr =
        DateFormat('HH:mm').format(message.createdAt.toLocal());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar (chỉ cho tin nhắn không phải của mình)
          if (!isMine) ...[
            SizedBox(
              width: 36,
              child: showAvatar
                  ? VibeAvatar(
                      name: message.senderName,
                      imageUrl: message.senderAvatarUrl,
                      size: 32,
                      showBorder: false,
                    )
                  : const SizedBox(),
            ),
            const SizedBox(width: 6),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showSenderName && !isMine)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      message.senderName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isMine)
                      Padding(
                        padding: const EdgeInsets.only(right: 6, bottom: 2),
                        child: Text(
                          timeStr,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: isMine
                              ? AppColors.primaryGradient
                              : null,
                          color: isMine
                              ? null
                              : (isDark
                                  ? AppColors.darkBgSecondary
                                  : Colors.white),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: isMine
                                ? const Radius.circular(18)
                                : const Radius.circular(4),
                            bottomRight: isMine
                                ? const Radius.circular(4)
                                : const Radius.circular(18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.2 : 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          message.isDeleted
                              ? '🚫 Tin nhắn đã bị xóa'
                              : message.content,
                          style: TextStyle(
                            fontSize: 14,
                            color: isMine
                                ? Colors.white
                                : (isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary),
                            fontStyle: message.isDeleted
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                      ),
                    ),
                    if (!isMine)
                      Padding(
                        padding: const EdgeInsets.only(left: 6, bottom: 2),
                        child: Text(
                          timeStr,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          if (isMine) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ─── Date Separator ───────────────────────────────────────────────────────────

class _DateSep extends StatelessWidget {
  const _DateSep({required this.date});
  final DateTime date;

  String _format(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return 'Hôm nay';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.day == yesterday.day &&
        dt.month == yesterday.month &&
        dt.year == yesterday.year) {
      return 'Hôm qua';
    }
    return DateFormat('dd/MM/yyyy').format(dt);
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
