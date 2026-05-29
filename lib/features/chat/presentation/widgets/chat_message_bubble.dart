// lib/features/chat/presentation/widgets/chat_message_bubble.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../domain/entities/chat_conversation.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.showAvatar,
    required this.showSenderName,
  });

  final ChatMockMessage message;
  final bool isMine;
  final bool showAvatar;
  final bool showSenderName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMine ? 56 : 0,
        right: isMine ? 0 : 56,
        top: 2,
        bottom: 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMine) ...[
            SizedBox(
              width: 36,
              child: showAvatar
                  ? VibeAvatar(
                      name: message.senderName,
                      imageUrl: message.senderAvatar,
                      size: 34,
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMine && showSenderName) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      message.senderName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHint,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isMine) ...[
                      _TimeStampText(timestamp: message.timestamp),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: _BubbleContainer(
                        content: message.content,
                        isMine: isMine,
                      ),
                    ),
                    if (!isMine) ...[
                      const SizedBox(width: 6),
                      _TimeStampText(timestamp: message.timestamp),
                    ],
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

class _BubbleContainer extends StatelessWidget {
  const _BubbleContainer({required this.content, required this.isMine});

  final String content;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    if (isMine) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          content,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        content,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
      ),
    );
  }
}

class _TimeStampText extends StatelessWidget {
  const _TimeStampText({required this.timestamp});

  final DateTime timestamp;

  String _format(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _format(timestamp),
      style: const TextStyle(
        fontSize: 10,
        color: AppColors.textHint,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
