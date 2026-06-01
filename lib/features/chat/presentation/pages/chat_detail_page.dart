// lib/features/chat/presentation/pages/chat_detail_page.dart
//
// ChatDetailPage — Kết nối backend thật (API + SignalR)
// Được điều hướng từ EventDetailPage, ChatInboxPage, OtherUserProfilePage
//
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/signalr_service.dart';
import '../../../../core/utils/profile_state.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../injection/injection_container.dart';
import '../../../profile/data/services/user_api_service.dart';
import '../../../profile/presentation/pages/other_user_profile_page.dart';
import '../../data/models/chat_room_model.dart';
import '../../data/services/chat_api_service.dart';
import '../../data/services/signalr_chat_service.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';

class ChatDetailPage extends StatefulWidget {
  const ChatDetailPage({super.key, required this.room});

  final ChatRoomModel room;

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage>
    with WidgetsBindingObserver {
  late final ChatCubit _cubit;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _typingDebounce;
  StreamSubscription<PresenceEventModel>? _presenceSub;
  final Set<String> _onlineUserIds = {};
  bool _isSendButtonEnabled = false;
  bool _isUploadingImage = false;
  late bool _roomOnline;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit = sl<ChatCubit>();
    _roomOnline = widget.room.isOnline;
    if (widget.room.otherUserId != null && widget.room.isOnline) {
      _onlineUserIds.add(widget.room.otherUserId!.toLowerCase());
    }
    _presenceSub = sl<SignalRChatService>().onPresenceChanged.listen(
      _onPresenceChanged,
    );
    _loadRoomPresence();
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
    WidgetsBinding.instance.removeObserver(this);
    _typingDebounce?.cancel();
    _presenceSub?.cancel();
    _inputController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _loadRoomPresence() async {
    if (!widget.room.isGroup) return;

    try {
      final members = await sl<ChatApiService>().getRoomMembers(widget.room.id);
      if (!mounted) return;
      setState(() {
        _onlineUserIds
          ..clear()
          ..addAll(
            members.where((m) => m.isOnline).map((m) => m.userId.toLowerCase()),
          );
      });
    } catch (_) {
      // Presence is progressive; chat can still render without it.
    }
  }

  void _onPresenceChanged(PresenceEventModel event) {
    if (event.chatRoomId != widget.room.id || !mounted) return;

    setState(() {
      final userId = event.userId.toLowerCase();
      if (event.isOnline) {
        _onlineUserIds.add(userId);
      } else {
        _onlineUserIds.remove(userId);
      }

      if (widget.room.otherUserId?.toLowerCase() == userId) {
        _roomOnline = event.isOnline;
      }
    });
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animate) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
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
      await _cubit.sendMessage(text, messageType: 'Text');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gửi thất bại: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _handlePickImage() async {
    if (_isUploadingImage) return;

    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;

      HapticFeedback.selectionClick();
      setState(() => _isUploadingImage = true);

      final imageUrl = await sl<ChatApiService>().uploadChatImage(image.path);
      await _cubit.sendMessage(imageUrl, messageType: 'Image');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
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
        backgroundColor: isDark
            ? AppColors.darkBgPrimary
            : const Color(0xFFF2F4FF),
        body: BlocConsumer<ChatCubit, ChatState>(
          listenWhen: (prev, curr) => curr is ChatMessagesLoaded,
          listener: (context, state) {
            if (state is ChatMessagesLoaded) _scrollToBottom();
          },
          builder: (context, state) {
            return Column(
              children: [
                _AppBarWidget(
                  room: widget.room,
                  isDark: isDark,
                  isOnline: _roomOnline,
                ),
                Expanded(child: _buildBody(state, isDark)),
                _buildInput(isDark, state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(ChatState state, bool isDark) {
    if (state is ChatLoading ||
        state is ChatRoomOpening ||
        state is ChatInitial) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Đang tải tin nhắn...',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textHint,
              ),
            ),
          ],
        ),
      );
    }

    if (state is ChatError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _cubit.openChatRoom(widget.room),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Thử lại'),
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

    if (state is ChatMessagesLoaded) {
      final messages = state.messages;

      return Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _buildEmpty(isDark)
                : ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final msg = messages[i];
                      final prev = i > 0 ? messages[i - 1] : null;
                      final next = i < messages.length - 1
                          ? messages[i + 1]
                          : null;

                      final showDateSep =
                          prev == null ||
                          !_sameDay(msg.createdAt, prev.createdAt);
                      final showSenderName =
                          !msg.isMine &&
                          (prev == null ||
                              prev.senderId != msg.senderId ||
                              showDateSep);
                      final showAvatar =
                          !msg.isMine &&
                          (next == null || next.senderId != msg.senderId);
                      final isFirst =
                          prev == null ||
                          prev.senderId != msg.senderId ||
                          showDateSep;
                      final isLast =
                          next == null || next.senderId != msg.senderId;

                      return Column(
                        children: [
                          if (showDateSep) _DateSeparator(date: msg.createdAt),
                          Padding(
                            padding: EdgeInsets.only(
                              top: isFirst ? 8 : 2,
                              bottom: isLast ? 8 : 2,
                            ),
                            child: _MessageBubble(
                              message: msg,
                              showSenderName: showSenderName,
                              showAvatar: showAvatar,
                              isFirst: isFirst,
                              isLast: isLast,
                              isDark: isDark,
                              isSenderOnline:
                                  widget.room.isGroup &&
                                  _onlineUserIds.contains(
                                    msg.senderId.toLowerCase(),
                                  ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // Typing indicator
          if (state.typingUserNames.isNotEmpty)
            _TypingIndicator(names: state.typingUserNames, isDark: isDark),
        ],
      );
    }

    return const SizedBox();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.day == b.day && a.month == b.month && a.year == b.year;

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.chat_bubble_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Chưa có tin nhắn nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: isDark ? AppColors.darkTextPrimary : AppColors.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy gửi tin nhắn đầu tiên! 👋',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(bool isDark, ChatState state) {
    final isSending = state is ChatMessagesLoaded && state.isSending;
    final isBusy = isSending || _isUploadingImage;

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _ImagePickButton(
            enabled: !isBusy,
            loading: _isUploadingImage,
            isDark: isDark,
            onTap: _handlePickImage,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBgTertiary
                    : const Color(0xFFF2F4FF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorderLight
                      : AppColors.borderLight,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _inputController,
                focusNode: _focusNode,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                onChanged: _handleTyping,
                enabled: !isBusy,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _SendButton(
            enabled: _isSendButtonEnabled && !isBusy,
            sending: isSending,
            onTap: _handleSend,
          ),
        ],
      ),
    );
  }
}

// ─── App Bar ─────────────────────────────────────────────────────────────────────────────────

class _AppBarWidget extends StatelessWidget {
  const _AppBarWidget({
    required this.room,
    required this.isDark,
    required this.isOnline,
  });

  final ChatRoomModel room;
  final bool isDark;
  final bool isOnline;

  void _showMembers(BuildContext context) {
    if (!room.isGroup) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MembersBottomSheet(room: room, isDark: isDark),
    );
  }

  void _openDirectProfile(BuildContext context) {
    if (room.isGroup || room.otherUserId == null) {
      _showMembers(context);
      return;
    }

    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => OtherUserProfilePage(userId: room.otherUserId!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        left: 4,
        right: 8,
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
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
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
          // Room icon
          GestureDetector(
            onTap: () => _openDirectProfile(context),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (room.isGroup)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.group_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  )
                else
                  VibeAvatar(
                    name: room.name,
                    imageUrl: room.avatarUrl,
                    size: 44,
                    showBorder: false,
                  ),
                if (!room.isGroup)
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isOnline
                            ? const Color(0xFF22C55E)
                            : const Color(0xFF94A3B8),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBgSecondary
                              : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Title + subtitle
          Expanded(
            child: GestureDetector(
              onTap: () => _openDirectProfile(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    room.name,
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
                  Row(
                    children: [
                      Text(
                        room.isDirect
                            ? 'Tin nhắn riêng'
                            : room.isGroup
                            ? 'Nhóm chat sự kiện'
                            : 'Chat riêng',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textHint,
                        ),
                      ),
                      if (!room.isGroup) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isOnline
                                ? const Color(0xFF22C55E)
                                : const Color(0xFF94A3B8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isOnline
                                ? const Color(0xFF16A34A)
                                : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textHint),
                          ),
                        ),
                      ],
                      if (room.isGroup) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textHint,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Nút xem danh sách thành viên (chỉ hiện với nhóm)
          if (room.isGroup)
            IconButton(
              tooltip: 'Danh sách thành viên',
              icon: Icon(
                Icons.people_alt_rounded,
                color: isDark ? AppColors.darkTextSecondary : AppColors.primary,
                size: 22,
              ),
              onPressed: () => _showMembers(context),
            ),
        ],
      ),
    );
  }
}

// ─── Members Bottom Sheet ────────────────────────────────────────────────────

class _MembersBottomSheet extends StatefulWidget {
  const _MembersBottomSheet({required this.room, required this.isDark});
  final ChatRoomModel room;
  final bool isDark;

  @override
  State<_MembersBottomSheet> createState() => _MembersBottomSheetState();
}

class _MembersBottomSheetState extends State<_MembersBottomSheet> {
  List<ChatMemberModel>? _members;
  String? _error;
  bool _loading = true;
  String? _dmLoading;
  String? _friendLoading;
  StreamSubscription<PresenceEventModel>? _presenceSub;

  @override
  void initState() {
    super.initState();
    _presenceSub = sl<SignalRChatService>().onPresenceChanged.listen(
      _onPresenceChanged,
    );
    _fetchMembers();
  }

  @override
  void dispose() {
    _presenceSub?.cancel();
    super.dispose();
  }

  void _onPresenceChanged(PresenceEventModel event) {
    if (event.chatRoomId != widget.room.id || _members == null || !mounted) {
      return;
    }

    setState(() {
      _members = _members!
          .map(
            (m) => m.userId.toLowerCase() == event.userId.toLowerCase()
                ? m.copyWith(isOnline: event.isOnline)
                : m,
          )
          .toList();
    });
  }

  Future<void> _fetchMembers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final members = await sl<ChatApiService>().getRoomMembers(widget.room.id);
      if (mounted) {
        setState(() {
          _members = members;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _openDm(ChatMemberModel member) async {
    setState(() => _dmLoading = member.userId);
    try {
      final dm = await sl<ChatApiService>().openDirectMessage(member.userId);
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => ChatDetailPage(room: dm)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không thể mở tin nhắn: ${e.toString().split(':').last.trim()}',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _dmLoading = null);
    }
  }

  Future<void> _openProfile(ChatMemberModel member) async {
    final currentUserId = ProfileState.notifier.value.id;
    if (member.userId.toLowerCase() == currentUserId.toLowerCase()) return;

    Navigator.of(context).pop();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => OtherUserProfilePage(userId: member.userId),
      ),
    );
  }

  Future<void> _sendFriendRequest(ChatMemberModel member) async {
    setState(() => _friendLoading = member.userId);
    try {
      await sl<UserApiService>().requestFriend(member.userId);
      sl<SignalRService>().emitLocalChange('friendship', {
        'userId': member.userId,
      });
      if (!mounted) return;
      setState(() {
        _members = _members!
            .map(
              (m) => m.userId.toLowerCase() == member.userId.toLowerCase()
                  ? m.copyWith(friendshipStatus: 'Requested', isFriend: false)
                  : m,
            )
            .toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Friend request sent'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot send friend request: ${e.toString().split(':').last.trim()}',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _friendLoading = null);
    }
  }

  bool _isFriend(ChatMemberModel member) {
    final status = member.friendshipStatus.toLowerCase();
    return member.isFriend || status == 'accepted' || status == 'friend';
  }

  bool _isPendingFriend(ChatMemberModel member) {
    final status = member.friendshipStatus.toLowerCase();
    return status == 'requested' || status == 'pending';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final currentUserId = ProfileState.notifier.value.id;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBorderLight
                    : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.people_alt_rounded,
                    color: Colors.white,
                    size: 18,
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
                    if (_members != null)
                      Text(
                        '${_members!.length} người',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textHint,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorderLight : AppColors.borderLight,
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.textHint,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Không tải được danh sách',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textHint,
                    ),
                  ),
                  TextButton(
                    onPressed: _fetchMembers,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _members!.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  indent: 72,
                  endIndent: 16,
                  color: isDark
                      ? AppColors.darkBorderLight
                      : AppColors.borderLight,
                ),
                itemBuilder: (ctx, i) {
                  final m = _members![i];
                  final isSelf =
                      m.userId.toLowerCase() == currentUserId.toLowerCase();
                  final isOwner = m.role.toLowerCase() == 'owner';
                  final isDmLoading = _dmLoading == m.userId;
                  final isFriend = _isFriend(m);
                  final isPending = _isPendingFriend(m);
                  final isFriendLoading = _friendLoading == m.userId;

                  return ListTile(
                    onTap: isSelf ? null : () => _openProfile(m),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    leading: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        VibeAvatar(
                          name: m.name,
                          imageUrl: m.avatarUrl,
                          size: 44,
                          showBorder: false,
                        ),
                        Positioned(
                          bottom: 0,
                          right: -2,
                          child: Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              color: m.isOnline
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFF94A3B8),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBgSecondary
                                    : Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            isSelf ? '${m.name} (Bạn)' : m.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.secondary,
                            ),
                          ),
                        ),
                        if (isOwner)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Host',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      m.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: m.isOnline
                            ? const Color(0xFF16A34A)
                            : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textHint),
                      ),
                    ),
                    trailing: isSelf
                        ? null
                        : SizedBox(
                            width: 40,
                            height: 40,
                            child: isDmLoading || isFriendLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : IconButton(
                                    tooltip: isFriend
                                        ? 'Private message'
                                        : isPending
                                        ? 'Friend request pending'
                                        : 'Add friend',
                                    padding: EdgeInsets.zero,
                                    icon: Icon(
                                      isFriend
                                          ? Icons.chat_bubble_outline_rounded
                                          : isPending
                                          ? Icons.person_add_alt_1_rounded
                                          : Icons.person_add_alt_1_rounded,
                                      size: 20,
                                      color: isPending
                                          ? const Color(0xFF64748B)
                                          : AppColors.primary,
                                    ),
                                    onPressed: isPending
                                        ? null
                                        : () => isFriend
                                              ? _openDm(m)
                                              : _sendFriendRequest(m),
                                  ),
                          ),
                  );
                },
              ),
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}

// ─── Send Button ──────────────────────────────────────────────────────────────

class _ImagePickButton extends StatelessWidget {
  const _ImagePickButton({
    required this.enabled,
    required this.loading,
    required this.isDark,
    required this.onTap,
  });

  final bool enabled;
  final bool loading;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBgTertiary : const Color(0xFFF2F4FF),
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? AppColors.darkBorderLight : AppColors.borderLight,
          ),
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              )
            : Icon(
                Icons.photo_library_rounded,
                color: enabled ? AppColors.primary : AppColors.textHint,
                size: 21,
              ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.enabled,
    required this.sending,
    required this.onTap,
  });

  final bool enabled;
  final bool sending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.primaryGradient : null,
          color: enabled ? null : AppColors.bgSecondary,
          shape: BoxShape.circle,
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: sending
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
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  Icons.send_rounded,
                  key: ValueKey(enabled),
                  color: enabled ? Colors.white : AppColors.textHint,
                  size: 20,
                ),
              ),
      ),
    );
  }
}

// ─── Typing Indicator ─────────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({required this.names, required this.isDark});

  final List<String> names;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final label = names.length == 1
        ? '${names[0]} đang nhập...'
        : '${names.join(', ')} đang nhập...';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBgSecondary : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DotsIndicator(),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textHint,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DotsIndicator extends StatefulWidget {
  @override
  State<_DotsIndicator> createState() => _DotsIndicatorState();
}

class _DotsIndicatorState extends State<_DotsIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
            final offset = ((_ctrl.value * 3 - i) % 1.0).clamp(0.0, 1.0);
            final opacity = (offset < 0.5 ? offset * 2 : (1.0 - offset) * 2)
                .clamp(0.3, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.showSenderName,
    required this.showAvatar,
    required this.isFirst,
    required this.isLast,
    required this.isDark,
    required this.isSenderOnline,
  });

  final ChatMessageModel message;
  final bool showSenderName;
  final bool showAvatar;
  final bool isFirst;
  final bool isLast;
  final bool isDark;
  final bool isSenderOnline;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final timeStr = DateFormat('HH:mm').format(message.createdAt.toLocal());

    // Border radius logic — bubble curvature
    final radius = BorderRadius.only(
      topLeft: Radius.circular(isMine ? 20 : (isFirst ? 20 : 6)),
      topRight: Radius.circular(isMine ? (isFirst ? 20 : 6) : 20),
      bottomLeft: Radius.circular(isMine ? 20 : (isLast ? 20 : 6)),
      bottomRight: Radius.circular(isMine ? (isLast ? 20 : 6) : 20),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar — tin nhắn người khác
          if (!isMine) ...[
            SizedBox(
              width: 34,
              child: showAvatar
                  ? GestureDetector(
                      onTap: () {
                        if (message.senderId.isEmpty) return;
                        Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) =>
                                OtherUserProfilePage(userId: message.senderId),
                          ),
                        );
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          VibeAvatar(
                            name: message.senderName,
                            imageUrl: message.senderAvatarUrl,
                            size: 30,
                            showBorder: false,
                          ),
                          if (isSenderOnline)
                            Positioned(
                              bottom: 0,
                              right: 1,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.darkBgPrimary
                                        : const Color(0xFFF2F4FF),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  : const SizedBox(),
            ),
            const SizedBox(width: 6),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment: isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Tên người gửi
                if (showSenderName && !isMine)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _senderColor(message.senderId),
                      ),
                    ),
                  ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Thời gian — bên trái nếu isMine
                    if (isMine && isLast)
                      Padding(
                        padding: const EdgeInsets.only(right: 6, bottom: 3),
                        child: Text(
                          timeStr,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textHint,
                          ),
                        ),
                      ),

                    // Bubble
                    Flexible(
                      child: Container(
                        padding: _isImageMessage
                            ? const EdgeInsets.all(4)
                            : const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                        decoration: BoxDecoration(
                          gradient: isMine && !_isImageMessage
                              ? AppColors.primaryGradient
                              : null,
                          color: isMine
                              ? (_isImageMessage ? Colors.white : null)
                              : (isDark
                                    ? const Color(0xFF2A2D3E)
                                    : Colors.white),
                          borderRadius: radius,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.2 : 0.06,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _buildContent(isMine),
                      ),
                    ),

                    // Thời gian — bên phải nếu không phải mine
                    if (!isMine && isLast)
                      Padding(
                        padding: const EdgeInsets.only(left: 6, bottom: 3),
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

  bool get _isImageMessage =>
      !message.isDeleted && message.messageType.toLowerCase() == 'image';

  Widget _buildContent(bool isMine) {
    if (message.isDeleted) {
      return Text(
        'Message deleted',
        style: TextStyle(
          fontSize: 14.5,
          height: 1.4,
          color: isMine
              ? Colors.white
              : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    if (_isImageMessage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          message.content,
          width: 224,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 224,
              height: 160,
              alignment: Alignment.center,
              color: isDark ? const Color(0xFF202332) : AppColors.bgSecondary,
              child: const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 224,
              height: 150,
              alignment: Alignment.center,
              color: isDark ? const Color(0xFF202332) : AppColors.bgSecondary,
              child: const Icon(
                Icons.broken_image_rounded,
                color: AppColors.textHint,
                size: 34,
              ),
            );
          },
        ),
      );
    }

    return Text(
      message.content,
      style: TextStyle(
        fontSize: 14.5,
        height: 1.4,
        color: isMine
            ? Colors.white
            : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
      ),
    );
  }

  // Mỗi sender có màu khác nhau cho tên
  Color _senderColor(String senderId) {
    final colors = [
      AppColors.primary,
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF6366F1),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
    ];
    return colors[senderId.hashCode.abs() % colors.length];
  }
}

// ─── Date Separator ───────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});

  final DateTime date;

  String _format() {
    final now = DateTime.now();
    final local = date.toLocal();
    if (local.day == now.day &&
        local.month == now.month &&
        local.year == now.year)
      return 'Hôm nay';
    final yesterday = now.subtract(const Duration(days: 1));
    if (local.day == yesterday.day &&
        local.month == yesterday.month &&
        local.year == yesterday.year)
      return 'Hôm qua';
    return DateFormat('EEEE, dd/MM/yyyy', 'vi').format(local);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(
            child: Divider(color: AppColors.borderLight, thickness: 1),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _format(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const Expanded(
            child: Divider(color: AppColors.borderLight, thickness: 1),
          ),
        ],
      ),
    );
  }
}
