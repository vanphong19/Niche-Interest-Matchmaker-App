// lib/features/chat/presentation/pages/chat_inbox_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/chat_conversation.dart';
import '../widgets/chat_conversation_tile.dart';
import 'event_group_chat_page.dart';
import 'dm_conversation_page.dart';

class ChatInboxPage extends StatefulWidget {
  const ChatInboxPage({super.key});

  @override
  State<ChatInboxPage> createState() => _ChatInboxPageState();
}

class _ChatInboxPageState extends State<ChatInboxPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<ChatConversation> _conversations;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _conversations = List.from(ChatMockData.mockConversations);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<ChatConversation> get _groupChats => _conversations
      .where((c) =>
          c.type == ConversationType.groupChat &&
          (c.title.toLowerCase().contains(_searchQuery) ||
              _searchQuery.isEmpty))
      .toList();

  List<ChatConversation> get _directMessages => _conversations
      .where((c) =>
          c.type == ConversationType.directMessage &&
          (c.title.toLowerCase().contains(_searchQuery) ||
              _searchQuery.isEmpty))
      .toList();

  int get _totalUnread =>
      _conversations.fold(0, (sum, c) => sum + c.unreadCount);

  void _openConversation(ChatConversation conversation) {
    HapticFeedback.selectionClick();
    // Mark as read
    setState(() {
      final idx = _conversations.indexOf(conversation);
      if (idx >= 0) {
        _conversations[idx] = ChatConversation(
          id: conversation.id,
          type: conversation.type,
          title: conversation.title,
          avatarUrl: conversation.avatarUrl,
          eventId: conversation.eventId,
          eventEmoji: conversation.eventEmoji,
          participantIds: conversation.participantIds,
          participantNames: conversation.participantNames,
          participantAvatars: conversation.participantAvatars,
          lastMessage: conversation.lastMessage,
          lastMessageAt: conversation.lastMessageAt,
          lastMessageSenderName: conversation.lastMessageSenderName,
          unreadCount: 0,
          isOnline: conversation.isOnline,
        );
      }
    });

    if (conversation.type == ConversationType.groupChat) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EventGroupChatPage(
            eventId: conversation.eventId ?? conversation.id,
            eventTitle: conversation.title,
            eventEmoji: conversation.eventEmoji ?? '💬',
            members: ChatMockData.mockMembers,
          ),
        ),
      );
    } else {
      final otherUserId = conversation.participantIds
          .firstWhere((id) => id != ChatMockData.currentUserId,
              orElse: () => 'u2');
      final otherName = conversation.title;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DmConversationPage(
            userId: otherUserId,
            userName: otherName,
            isOnline: conversation.isOnline,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBgPrimary : const Color(0xFFF5F7FF),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          _buildSliverHeader(isDark),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildGroupList(isDark),
            _buildDmList(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverHeader(bool isDark) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor:
          isDark ? AppColors.darkBgSecondary : Colors.white,
      automaticallyImplyLeading: false,
      expandedHeight: 172,
      collapsedHeight: 56,
      bottom: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textHint,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        dividerColor:
            isDark ? AppColors.darkBorderLight : AppColors.borderLight,
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Nhóm'),
                if (_groupChats.any((c) => c.unreadCount > 0)) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_groupChats.fold(0, (s, c) => s + c.unreadCount)}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Trực tiếp'),
                if (_directMessages.any((c) => c.unreadCount > 0)) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_directMessages.fold(0, (s, c) => s + c.unreadCount)}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          color: isDark ? AppColors.darkBgSecondary : Colors.white,
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top + 16,
            20,
            56,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Messages',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.secondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (_totalUnread > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$_totalUnread',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_conversations.length} cuộc trò chuyện',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textHint,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Compose button
                  GestureDetector(
                    onTap: () => HapticFeedback.selectionClick(),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Search bar
              Container(
                height: 42,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBgTertiary
                      : AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorderLight
                        : AppColors.borderLight,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm...',
                    hintStyle:
                        TextStyle(color: AppColors.textHint, fontSize: 14),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupList(bool isDark) {
    final items = _groupChats;
    if (items.isEmpty) return _buildEmpty('Chưa có nhóm chat nào', isDark);
    return _buildList(items, isDark);
  }

  Widget _buildDmList(bool isDark) {
    final items = _directMessages;
    if (items.isEmpty) {
      return _buildEmpty('Chưa có tin nhắn trực tiếp', isDark);
    }
    return _buildList(items, isDark);
  }

  Widget _buildList(List<ChatConversation> items, bool isDark) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (_, i) => Divider(
        height: 1,
        indent: 86,
        endIndent: 0,
        color: isDark ? AppColors.darkBorderLight : AppColors.borderLight,
      ),
      itemBuilder: (_, i) {
        return ChatConversationTile(
          conversation: items[i],
          onTap: () => _openConversation(items[i]),
        );
      },
    );
  }

  Widget _buildEmpty(String message, bool isDark) {
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
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.secondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tham gia sự kiện để bắt đầu trò chuyện!',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
