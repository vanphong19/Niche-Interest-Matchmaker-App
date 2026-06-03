// lib/features/chat/presentation/pages/chat_inbox_page.dart
import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/signalr_service.dart';
import '../../../../core/utils/profile_state.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../injection/injection_container.dart';
import '../../data/models/chat_room_model.dart';
import '../../data/services/chat_api_service.dart';
import '../../data/services/signalr_chat_service.dart';
import 'chat_detail_page.dart';

@RoutePage()
class ChatInboxPage extends StatefulWidget {
  const ChatInboxPage({super.key});

  @override
  State<ChatInboxPage> createState() => _ChatInboxPageState();
}

class _ChatInboxPageState extends State<ChatInboxPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<ChatMessageModel>? _messageSub;
  StreamSubscription<PresenceEventModel>? _presenceSub;
  StreamSubscription<Map<String, dynamic>>? _dataChangeSub;
  String _searchQuery = '';

  List<ChatRoomModel> _allRooms = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(
      () => setState(() => _searchQuery = _searchController.text.toLowerCase()),
    );
    _fetchRooms();
    _connectRealtime();
    _dataChangeSub = sl<SignalRService>().dataChangeStream.listen(
      _onDataChanged,
    );
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _presenceSub?.cancel();
    _dataChangeSub?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRooms({bool showLoading = true}) async {
    try {
      if (showLoading) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }
      final rooms = await sl<ChatApiService>().getMyRooms();
      if (mounted) {
        setState(() {
          _allRooms = _sortRooms(rooms);
          if (!showLoading) _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        String errMsg = e.toString();
        // Rút gọn thông báo lỗi Dio để dễ đọc
        if (errMsg.contains('connection timeout') ||
            errMsg.contains('SocketException')) {
          errMsg =
              'Cannot connect to the backend. Check the server and try again.';
        } else if (errMsg.contains('401') || errMsg.contains('Unauthorized')) {
          errMsg = 'Your session has expired. Please sign in again.';
        } else if (errMsg.contains('403')) {
          errMsg = 'You do not have access.';
        }
        setState(() => _error = errMsg);
      }
    } finally {
      if (mounted && showLoading) setState(() => _isLoading = false);
    }
  }

  Future<void> _connectRealtime() async {
    final signalR = sl<SignalRChatService>();
    await signalR.connect();

    await _messageSub?.cancel();
    _messageSub = signalR.onMessageReceived.listen(_onMessageReceived);

    await _presenceSub?.cancel();
    _presenceSub = signalR.onPresenceChanged.listen(_onPresenceChanged);
  }

  void _onMessageReceived(ChatMessageModel rawMsg) {
    if (!mounted) return;

    final currentUserId = ProfileState.notifier.value.id;
    final isMine = rawMsg.senderId.toLowerCase() == currentUserId.toLowerCase();
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
      isDeleted: rawMsg.isDeleted,
    );

    final index = _allRooms.indexWhere(
      (room) => room.id.toLowerCase() == msg.chatRoomId.toLowerCase(),
    );

    if (index == -1) {
      _fetchRooms(showLoading: false);
      return;
    }

    setState(() {
      final rooms = List<ChatRoomModel>.from(_allRooms);
      final room = rooms[index];
      rooms[index] = room.copyWith(
        lastMessage: msg,
        unreadCount: isMine ? room.unreadCount : room.unreadCount + 1,
      );
      _allRooms = _sortRooms(rooms);
    });
  }

  void _onPresenceChanged(PresenceEventModel event) {
    if (!mounted) return;

    final index = _allRooms.indexWhere(
      (room) =>
          room.otherUserId?.toLowerCase() == event.userId.toLowerCase() &&
          room.id.toLowerCase() == event.chatRoomId.toLowerCase(),
    );

    if (index == -1) return;

    setState(() {
      final rooms = List<ChatRoomModel>.from(_allRooms);
      rooms[index] = rooms[index].copyWith(isOnline: event.isOnline);
      _allRooms = rooms;
    });
  }

  void _onDataChanged(Map<String, dynamic> event) {
    if (!mounted || event['_type'] != 'chat') return;

    final roomId = (event['roomId'] ?? '').toString();
    if (roomId.isEmpty) {
      _fetchRooms(showLoading: false);
      return;
    }

    final index = _allRooms.indexWhere(
      (room) => room.id.toLowerCase() == roomId.toLowerCase(),
    );
    if (index == -1) {
      _fetchRooms(showLoading: false);
      return;
    }

    setState(() {
      final rooms = List<ChatRoomModel>.from(_allRooms);
      rooms[index] = rooms[index].copyWith(unreadCount: 0);
      _allRooms = rooms;
    });
  }

  List<ChatRoomModel> _sortRooms(List<ChatRoomModel> rooms) {
    final sorted = List<ChatRoomModel>.from(rooms);
    sorted.sort((a, b) {
      final aTime = a.lastMessage?.createdAt ?? a.createdAtUtc;
      final bTime = b.lastMessage?.createdAt ?? b.createdAtUtc;
      return bTime.compareTo(aTime);
    });
    return sorted;
  }

  List<ChatRoomModel> get _groupRooms => _allRooms
      .where(
        (r) =>
            r.isGroup &&
            (r.name.toLowerCase().contains(_searchQuery) ||
                _searchQuery.isEmpty),
      )
      .toList();

  List<ChatRoomModel> get _directRooms => _allRooms
      .where(
        (r) =>
            !r.isGroup &&
            (r.name.toLowerCase().contains(_searchQuery) ||
                _searchQuery.isEmpty),
      )
      .toList();

  int get _totalUnread => _allRooms.fold(0, (s, r) => s + r.unreadCount);

  void _openRoom(ChatRoomModel room) {
    HapticFeedback.selectionClick();
    Navigator.of(context)
        .push<void>(
          MaterialPageRoute(builder: (_) => ChatDetailPage(room: room)),
        )
        .then((_) {
          if (!mounted) return;
          setState(() {
            _allRooms = _allRooms
                .map((r) => r.id == room.id ? r.copyWith(unreadCount: 0) : r)
                .toList();
          });
          sl<SignalRService>().emitLocalChange('chat', {'roomId': room.id});
        });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBgPrimary
          : const Color(0xFFF5F7FF),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [_buildSliverHeader(isDark)],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildErrorState(isDark)
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildRoomList(
                    _groupRooms,
                    isDark,
                    emptyMsg: 'No group chats yet',
                  ),
                  _buildRoomList(
                    _directRooms,
                    isDark,
                    emptyMsg: 'No direct messages yet',
                  ),
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
      backgroundColor: isDark ? AppColors.darkBgSecondary : Colors.white,
      automaticallyImplyLeading: false,
      expandedHeight: 230,
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
        dividerColor: isDark
            ? AppColors.darkBorderLight
            : AppColors.borderLight,
        tabs: [
          _buildTab('Groups', _groupRooms.fold(0, (s, r) => s + r.unreadCount)),
          _buildTab(
            'Direct',
            _directRooms.fold(0, (s, r) => s + r.unreadCount),
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
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.secondary,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 4),
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
                                  horizontal: 8,
                                  vertical: 3,
                                ),
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
                          '${_allRooms.length} conversations',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textHint,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
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
                    hintText: 'Search conversations...',
                    hintStyle: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Tab _buildTab(String label, int unread) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (unread > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$unread',
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
    );
  }

  Widget _buildRoomList(
    List<ChatRoomModel> rooms,
    bool isDark, {
    required String emptyMsg,
  }) {
    if (rooms.isEmpty) return _buildEmpty(emptyMsg, isDark);

    return RefreshIndicator(
      onRefresh: _fetchRooms,
      color: AppColors.primary,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: rooms.length,
        separatorBuilder: (_, index) => Divider(
          height: 1,
          indent: 80,
          color: isDark ? AppColors.darkBorderLight : AppColors.borderLight,
        ),
        itemBuilder: (_, i) => _RoomTile(
          room: rooms[i],
          isDark: isDark,
          onTap: () => _openRoom(rooms[i]),
        ),
      ),
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
              color: isDark ? AppColors.darkTextPrimary : AppColors.secondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Join events to start conversations.',
            style: TextStyle(fontSize: 13, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.textHint,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load messages',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchRooms,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Room Tile ────────────────────────────────────────────────────────────────

class _RoomTile extends StatelessWidget {
  const _RoomTile({
    required this.room,
    required this.isDark,
    required this.onTap,
  });

  final ChatRoomModel room;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final currentUserId = ProfileState.notifier.value.id;
    final lastMsg = room.lastMessage;
    final timeStr = lastMsg != null ? _formatTime(lastMsg.createdAt) : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Avatar
              _RoomAvatar(room: room, isDark: isDark),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: room.unreadCount > 0
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.secondary,
                            ),
                          ),
                        ),
                        if (timeStr.isNotEmpty)
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: room.unreadCount > 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: room.unreadCount > 0
                                  ? AppColors.primary
                                  : AppColors.textHint,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _lastMessagePreview(lastMsg, currentUserId),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: room.unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: room.unreadCount > 0
                                  ? (isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.textPrimary)
                                  : AppColors.textHint,
                            ),
                          ),
                        ),
                        if (room.unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${room.unreadCount}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _lastMessagePreview(ChatMessageModel? msg, String currentUserId) {
    if (msg == null) return 'No messages yet';
    if (msg.isDeleted) return '🚫 Message deleted';
    final prefix = msg.senderId.toLowerCase() == currentUserId.toLowerCase()
        ? 'You: '
        : (room.isGroup ? '${msg.senderName}: ' : '');
    final content = msg.messageType.toLowerCase() == 'image'
        ? '1 photo has been sent'
        : msg.content;
    return '$prefix$content';
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    final diff = now.difference(local);
    if (diff.inDays == 0) return DateFormat('HH:mm').format(local);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat('E', 'vi').format(local);
    return DateFormat('dd/MM').format(local);
  }
}

// ─── Room Avatar ──────────────────────────────────────────────────────────────

class _RoomAvatar extends StatelessWidget {
  const _RoomAvatar({required this.room, required this.isDark});
  final ChatRoomModel room;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (room.isGroup) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(Icons.group_rounded, color: Colors.white, size: 26),
        ),
      );
    }

    // DM: dùng avatar nếu có
    return Stack(
      clipBehavior: Clip.none,
      children: [
        VibeAvatar(
          name: room.name,
          imageUrl: room.avatarUrl,
          size: 52,
          showBorder: false,
        ),
        Positioned(
          bottom: 1,
          right: 1,
          child: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: room.isOnline
                  ? const Color(0xFF22C55E)
                  : const Color(0xFF94A3B8),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.darkBgPrimary : Colors.white,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
