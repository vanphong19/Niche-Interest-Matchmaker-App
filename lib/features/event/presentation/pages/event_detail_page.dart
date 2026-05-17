import 'dart:async';
import 'dart:ui';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/profile_state.dart';
import '../../../../injection/injection_container.dart';
import '../../data/services/event_api_service.dart';
import '../../../profile/data/services/user_api_service.dart';
import '../../domain/entities/event.dart';
import '../../../../router/app_router.gr.dart';
import '../../../../core/services/signalr_service.dart';
import '../../../../core/widgets/vibe_empty_state.dart';
import '../../../../core/widgets/vibe_loading.dart';
import '../../../../core/widgets/snackbar_service.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../core/widgets/vibe_header.dart';
import 'event_members_page.dart';
import '../bloc/event_detail_cubit.dart';

@RoutePage()
class EventDetailPage extends StatefulWidget {
  const EventDetailPage({super.key, @PathParam('id') required this.eventId});

  final String eventId;

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage>
    with SingleTickerProviderStateMixin {
  late final EventDetailCubit _cubit;
  late final AnimationController _fabAnim;
  StreamSubscription? _statusSubscription;
  final Set<String> _requestedFriendIds = {};
  int _currentImageIndex = 0;

  late final ScrollController _scrollController;
  bool _isScrolled = false;

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    const threshold = 220.0;
    final scrolled = _scrollController.offset > threshold;
    if (scrolled != _isScrolled) {
      setState(() {
        _isScrolled = scrolled;
      });
    }
  }

  String _safeImage(
    String? url, {
    String fallback =
        'https://api-prod-minimal-v700.pages.dev/assets/images/cover/cover-1.webp',
  }) {
    final value = (url ?? '').trim();
    if (value.isEmpty || !value.startsWith('http')) return fallback;
    return value;
  }

  @override
  void initState() {
    super.initState();
    _cubit = sl<EventDetailCubit>();
    _cubit.loadEvent(widget.eventId);
    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _scrollController = ScrollController()..addListener(_onScroll);

    _statusSubscription = sl<SignalRService>().dataChangeStream.listen((data) {
      final eventId = (data['eventId'] ?? data['EventId'])?.toString();
      if (eventId == null || eventId == widget.eventId) {
        _cubit.loadEvent(widget.eventId);
      }
    });
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _cubit.close();
    _fabAnim.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _isHost(Event event) {
    final profile = ProfileState.notifier.value;
    if (event.hostId.isEmpty || profile.id.isEmpty) return false;
    return event.hostId.toLowerCase() == profile.id.toLowerCase();
  }

  bool _canManageMembers(Event event) {
    final ended = event.endDateTime?.isBefore(DateTime.now()) ?? false;
    return _isHost(event) &&
        !ended &&
        event.status != EventStatus.completed &&
        event.status != EventStatus.cancelled;
  }

  Future<void> _sendFriendRequest(String userId) async {
    if (userId.isEmpty) return;
    try {
      await sl<UserApiService>().requestFriend(userId);
      sl<SignalRService>().emitLocalChange('friendship', {'userId': userId});
      if (mounted) {
        setState(() => _requestedFriendIds.add(userId.toLowerCase()));
        VibeSnackBar.success(context, 'Friend request sent');
      }
    } catch (e) {
      if (mounted) VibeFeedback.apiError(context, e);
    }
  }

  Future<void> _copyJoinLink(Event event) async {
    final link = sl<EventApiService>().buildJoinRequestLink(event.id);
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    VibeSnackBar.success(context, 'Invite link copied!');
  }

  void _showMembersPopup(Event event) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MembersBottomSheet(event: event, isHost: _isHost(event)),
    );
  }

  Future<void> _openMembersManage(Event event) async {
    if (!_canManageMembers(event)) {
      VibeSnackBar.info(context, 'This event is done. Members are read-only.');
      _showMembersPopup(event);
      return;
    }
    // Try to use ManageEventRoute if available, otherwise fallback to EventMembersPage
    try {
      await context.router.push(ManageEventRoute(eventId: event.id));
    } catch (e) {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              EventMembersPage(eventId: event.id, isHost: _isHost(event)),
        ),
      );
    }
    if (mounted) _cubit.loadEvent(widget.eventId);
  }

  Future<void> _deleteEvent(Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vibe?'),
        content: const Text(
          'This action cannot be undone. All participants will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.heavyImpact();
      await sl<EventApiService>().deleteEvent(event.id);
      sl<SignalRService>().emitLocalChange('event', {'eventId': event.id});
      if (mounted) {
        context.router.popUntilRoot();
      }
    }
  }

  Future<void> _confirmJoinAction(Event event) async {
    if (event.isPending) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel request?'),
          content: const Text(
            'Your pending join request will be removed from this event.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep Request'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Cancel Request',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _cubit.toggleJoinLeave();
        sl<SignalRService>().emitLocalChange('event', {'eventId': event.id});
      }
      return;
    }

    if (!event.isJoined) {
      await _cubit.toggleJoinLeave();
      sl<SignalRService>().emitLocalChange('event', {'eventId': event.id});
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Vibe?'),
        content: const Text(
          'You will no longer be counted as a participant in this event.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Leave',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _cubit.toggleJoinLeave();
      sl<SignalRService>().emitLocalChange('event', {'eventId': event.id});
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FF),
        body: ValueListenableBuilder<ProfileData>(
          valueListenable: ProfileState.notifier,
          builder: (context, profile, child) {
            return BlocBuilder<EventDetailCubit, EventDetailState>(
              builder: (context, state) {
                if (state is EventDetailLoading ||
                    state is EventDetailInitial) {
                  return const _LoadingShimmer();
                } else if (state is EventDetailError) {
                  return _buildError(state.message);
                } else if (state is EventDetailLoaded) {
                  final event = state.event;
                  final userId = profile.id.toLowerCase();
                  final isParticipant = event.participantIds.any(
                    (id) => id.toLowerCase() == userId,
                  );
                  final isHost = _isHost(event);

                  if (!event.isPublic && !isParticipant && !isHost) {
                    return _buildError(
                      'This is a private event. You must be invited to view it.',
                      title: 'Private event',
                      actionLabel: 'Back to Home',
                      onAction: () =>
                          context.router.replaceAll([const BaseRoute()]),
                    );
                  }

                  return Stack(
                    children: [
                      CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        slivers: [
                          _buildSliverAppBar(event),
                          SliverToBoxAdapter(child: _buildContent(event)),
                        ],
                      ),
                      _buildBottomBar(event, state.isJoining),
                    ],
                  );
                }
                return const SizedBox();
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildError(
    String message, {
    String title = 'Could not open event',
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: VibeEmptyState(
            title: title,
            message: message,
            icon: Icons.lock_outline_rounded,
            actionLabel: actionLabel,
            onAction: onAction,
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(Event event) {
    int preset = -1;
    if (event.vibeTags != null) {
      final tags = event.vibeTags!.split(',').map((t) => t.trim());
      for (final t in tags) {
        if (t.startsWith('preset:')) {
          preset = int.tryParse(t.substring(7)) ?? -1;
          break;
        }
      }
    }

    List<Color> gradientColors;
    if (preset == 0) {
      // Deep Space
      gradientColors = [
        const Color(0xFF161B3A).withValues(alpha: 0.2),
        const Color(0xFF28418D).withValues(alpha: 0.4),
        const Color(0xFF1EB9D8).withValues(alpha: 0.7),
      ];
    } else if (preset == 1) {
      // Ocean Neon
      gradientColors = [
        const Color(0xFF0B1220).withValues(alpha: 0.2),
        const Color(0xFF123E68).withValues(alpha: 0.4),
        const Color(0xFF2A6EF3).withValues(alpha: 0.7),
      ];
    } else if (preset == 2) {
      // Sunset Blaze
      gradientColors = [
        const Color(0xFF1B1333).withValues(alpha: 0.2),
        const Color(0xFF503EA3).withValues(alpha: 0.4),
        const Color(0xFF2D95EA).withValues(alpha: 0.7),
      ];
    } else {
      gradientColors = [
        Colors.black.withValues(alpha: 0.2),
        Colors.transparent,
        Colors.black.withValues(alpha: 0.7),
      ];
    }

    final imageUrls = event.photoUrls.isNotEmpty
        ? event.photoUrls.map((u) => _safeImage(u)).toList()
        : [
            'https://api-prod-minimal-v700.pages.dev/assets/images/cover/cover-${(event.id.hashCode % 20) + 1}.webp',
          ];

    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final btnDark = _isScrolled ? isDarkTheme : true;

    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 60,
      toolbarHeight: 64.0,
      centerTitle: true,
      title: AnimatedOpacity(
        opacity: _isScrolled ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Text(
          event.title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: isDarkTheme ? Colors.white : AppColors.secondary,
          ),
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: Center(
          child: VibeHeaderButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => context.router.maybePop(),
            isDark: btnDark,
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Center(
            child: VibeHeaderButton(
              icon: Icons.ios_share_rounded,
              onTap: () => _copyJoinLink(event),
              isDark: btnDark,
            ),
          ),
        ),
      ],
      flexibleSpace: Stack(
        children: [
          if (_isScrolled)
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    color: isDarkTheme
                        ? const Color(0xFF0E121A).withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrls.length == 1)
                    Image.network(
                      imageUrls[0],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.bgSecondary,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: AppColors.textHint,
                          size: 40,
                        ),
                      ),
                    )
                  else
                    PageView.builder(
                      itemCount: imageUrls.length,
                      onPageChanged: (i) =>
                          setState(() => _currentImageIndex = i),
                      itemBuilder: (context, i) {
                        return Image.network(
                          imageUrls[i],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.bgSecondary,
                            child: const Icon(
                              Icons.image_not_supported,
                              color: AppColors.textHint,
                              size: 40,
                            ),
                          ),
                        );
                      },
                    ),
                  // Gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: gradientColors,
                        stops: preset >= 0
                            ? const [0.0, 0.5, 1.0]
                            : const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                  // Bottom text overlay
                  Positioned(
                    bottom: 44,
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CategoryPill(event: event),
                        const SizedBox(height: 10),
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (imageUrls.length > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          imageUrls.length,
                          (i) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentImageIndex == i ? 16 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _currentImageIndex == i
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
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

  Widget _buildContent(Event event) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      transform: Matrix4.translationValues(0, -12, 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 160),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // AI Match (if compatible)
            if (event.matchScore > 0) ...[
              _buildAIMatchCard(event),
              const SizedBox(height: 20),
            ],

            // Event Details (Time, Status, etc.)
            _buildEventDetailsSection(event),
            const SizedBox(height: 20),

            // Location Card
            _buildLocationSection(event),
            const SizedBox(height: 20),

            // Host card
            _buildHostCard(event),
            const SizedBox(height: 20),

            // Vibe Gallery (if multiple photos)
            _buildGallerySection(event),
            if (event.photoUrls.length > 1) const SizedBox(height: 20),

            // Vibe Tags (Chips)
            _buildVibeTagsSection(event),
            if (event.vibeTags != null && event.vibeTags!.isNotEmpty)
              const SizedBox(height: 20),

            // The Circle (Members)
            _buildCircleCard(event),
            const SizedBox(height: 20),

            // About Section (Description)
            _buildAboutSection(event),
          ],
        ),
      ),
    );
  }

  Widget _buildHostCard(Event event) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C2C58).withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              VibeAvatar(
                imageUrl: event.hostAvatar,
                name: event.hostName,
                size: 52,
                showBorder: false,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HOSTED BY',
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.hostName.isNotEmpty
                      ? event.hostName
                      : 'Unknown Vibe Caster',
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          if (!_isHost(event) &&
              !event.isHostFriend &&
              !_requestedFriendIds.contains(event.hostId.toLowerCase()))
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _sendFriendRequest(event.hostId);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Add friend',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          if (!_isHost(event) &&
              (event.isHostFriend ||
                  _requestedFriendIds.contains(event.hostId.toLowerCase())))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                event.isHostFriend ? 'Friend' : 'Requested',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAIMatchCard(Event event) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'AI Vibe Match',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${event.matchScore.toInt()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (event.matchScore / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    minHeight: 7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleCard(Event event) {
    final progress = event.maxParticipants > 0
        ? (event.currentParticipants / event.maxParticipants).clamp(0.0, 1.0)
        : 0.0;
    final isFull = event.currentParticipants >= event.maxParticipants;

    return GestureDetector(
      onTap: () => _showMembersPopup(event),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1C2C58).withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.group_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'The Circle',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${event.currentParticipants} joined',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            TextSpan(
                              text: ' of ${event.maxParticipants}',
                              style: const TextStyle(
                                color: AppColors.textHint,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isFull
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isFull ? 'Full' : 'View',
                        style: TextStyle(
                          color: isFull ? AppColors.error : AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: isFull ? AppColors.error : AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.borderLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isFull ? AppColors.error : AppColors.primary,
                ),
                minHeight: 8,
              ),
            ),
            // Avatars
            if (event.participantAvatars.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  SizedBox(
                    height: 36,
                    width:
                        (event.participantAvatars.take(6).length * 26)
                            .toDouble() +
                        12,
                    child: Stack(
                      children: event.participantAvatars
                          .take(6)
                          .toList()
                          .asMap()
                          .entries
                          .map((e) {
                            return Positioned(
                              left: e.key * 22.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: VibeAvatar(
                                  imageUrl: e.value,
                                  size: 32,
                                  showBorder: false,
                                ),
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (event.currentParticipants > 6)
                    Text(
                      '+${event.currentParticipants - 6} more',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  const Spacer(),
                  // Tap hint
                  const Row(
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        size: 14,
                        color: AppColors.textHint,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Tap to see all',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatFullDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/${dt.year}  $hour:$minute';
  }

  Widget _buildEventDetailsSection(Event event) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C2C58).withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Event Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 14),
          // Time range
          _detailRow(
            Icons.schedule_rounded,
            'Start',
            _formatFullDateTime(event.startDateTime),
            const Color(0xFF5856D6),
          ),
          if (event.endDateTime != null) ...[
            const SizedBox(height: 10),
            _detailRow(
              Icons.timelapse_rounded,
              'End',
              _formatFullDateTime(event.endDateTime!),
              const Color(0xFF5856D6),
            ),
          ],
          const SizedBox(height: 10),
          const Divider(color: AppColors.borderLight, height: 1),
          const SizedBox(height: 10),
          // Status indicators
          Row(
            children: [
              _statusPill(
                icon: event.isPublic
                    ? Icons.public_rounded
                    : Icons.lock_rounded,
                label: event.isPublic ? 'Public' : 'Private',
                color: event.isPublic
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 8),
              if (event.isEliteOnly)
                _statusPill(
                  icon: Icons.workspace_premium_rounded,
                  label: 'Elite Only',
                  color: const Color(0xFFFFD700),
                ),
              const Spacer(),
              _statusPill(
                icon: Icons.circle,
                label:
                    event.status.name[0].toUpperCase() +
                    event.status.name.substring(1),
                color: event.status == EventStatus.active
                    ? const Color(0xFF10B981)
                    : (event.status == EventStatus.cancelled
                          ? AppColors.error
                          : AppColors.textHint),
                iconSize: 8,
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.borderLight, height: 1),
          const SizedBox(height: 10),
          // Created date
          _detailRow(
            Icons.event_note_rounded,
            'Created',
            _formatFullDateTime(event.createdAt),
            AppColors.textHint,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textHint,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _statusPill({
    required IconData icon,
    required String label,
    required Color color,
    double iconSize = 14,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: iconSize),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVibeTagsSection(Event event) {
    final rawTags = event.vibeTags ?? '';
    if (rawTags.isEmpty) return const SizedBox.shrink();

    final tags = rawTags
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty && !t.startsWith('preset:'))
        .toList();
    if (tags.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            const Text(
              'Vibe Highlights',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.secondary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '#',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAboutSection(Event event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'The Vibe Breakdown',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.secondary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1C2C58).withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            event.description.isNotEmpty
                ? event.description
                : 'No description provided for this vibe.',
            style: TextStyle(
              color: event.description.isNotEmpty
                  ? const Color(0xFF4B5563)
                  : AppColors.textHint,
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w500,
              fontStyle: event.description.isNotEmpty
                  ? FontStyle.normal
                  : FontStyle.italic,
            ),
          ),
        ),
        if (_canManageMembers(event)) ...[
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _openMembersManage(event),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.manage_accounts_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Manage Members & Requests',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGallerySection(Event event) {
    if (event.photoUrls.length <= 1) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vibe Gallery',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: event.photoUrls.length,
            itemBuilder: (context, index) {
              final url = _safeImage(event.photoUrls[index]);
              return GestureDetector(
                onTap: () => _openFullImage(context, url),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage(url),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1C2C58).withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withValues(alpha: 0.9),
              ),
            ),
            InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 20,
              child: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(Event event, bool isJoining) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.95),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Price',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        event.price == null || event.price == 0
                            ? 'Free'
                            : '\$${event.price!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _fabAnim,
                      builder: (context, child) => Transform.scale(
                        scale: 0.9 + 0.1 * _fabAnim.value,
                        child: child,
                      ),
                      child: ElevatedButton(
                        onPressed: isJoining
                            ? null
                            : (_isHost(event)
                                  ? () => _deleteEvent(event)
                                  : () => _confirmJoinAction(event)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isHost(event) || event.isJoined
                              ? const Color(0xFFFFF0F0)
                              : (event.isPending
                                    ? AppColors.bgSecondary
                                    : AppColors.primary),
                          foregroundColor: _isHost(event) || event.isJoined
                              ? AppColors.error
                              : (event.isPending
                                    ? AppColors.textHint
                                    : Colors.white),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        child: isJoining
                            ? const VibeLoading(
                                size: 22,
                                strokeWidth: 2.5,
                                color: Colors.white,
                                segments: 10,
                              )
                            : Text(
                                _isHost(event)
                                    ? '✗  Delete Vibe'
                                    : (event.isJoined
                                          ? '✗  Leave Vibe'
                                          : (event.isPending
                                                ? 'Cancel Request'
                                                : '🚀  Join Vibe')),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection(Event event) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C2C58).withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.error,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'The Venue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event.location.name.isNotEmpty
                          ? event.location.name
                          : 'Location TBD',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (event.location.address.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.map_outlined,
                  size: 16,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.location.address,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                context.router.push(
                  LocationPickerRoute(
                    initialLocation:
                        '${event.location.name}\n${event.location.address}'
                            .trim(),
                    initialPosition: LatLng(
                      event.location.latitude,
                      event.location.longitude,
                    ),
                    isReadOnly: true,
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Center(
                  child: Text(
                    'Get Directions',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Category Pill ────────────────────────────────────────────────────────────
class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.event});
  final Event event;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
              ),
              child: Text(
                '${event.categoryEmoji} ${event.categoryName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
        if (event.isEliteOnly)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x40FFD700),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x80FFD700)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 12,
                      color: Color(0xFFFFD700),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Elite Only',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Members Bottom Sheet ─────────────────────────────────────────────────────
class _MembersBottomSheet extends StatefulWidget {
  const _MembersBottomSheet({required this.event, required this.isHost});
  final Event event;
  final bool isHost;

  @override
  State<_MembersBottomSheet> createState() => _MembersBottomSheetState();
}

class _MembersBottomSheetState extends State<_MembersBottomSheet> {
  late Future<List<Map<String, String>>> _membersFuture;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _membersFuture = sl<EventApiService>().getEventParticipants(
      widget.event.id,
    );
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.55, 0.72, 0.95],
      builder: (context, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C2233) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : const Color(0xFFDDE2EF),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'The Circle',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.secondary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${widget.event.currentParticipants}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      ' / ${widget.event.maxParticipants} members',
                                  style: const TextStyle(
                                    color: AppColors.textHint,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : AppColors.bgSecondary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Capacity progress
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: widget.event.maxParticipants > 0
                        ? (widget.event.currentParticipants /
                                  widget.event.maxParticipants)
                              .clamp(0.0, 1.0)
                        : 0,
                    backgroundColor: AppColors.borderLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: TextField(
                  controller: _searchCtrl,
                  textAlignVertical: TextAlignVertical.center,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    constraints: const BoxConstraints(maxHeight: 45),
                    hintText: 'Search members…',
                    hintStyle: TextStyle(
                      color: isDark
                          ? AppColors.darkTextHint
                          : AppColors.textHint,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: Container(
                      width: 46,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 0,
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? Container(
                            width: 40,
                            alignment: Alignment.center,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.close_rounded, size: 20),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {});
                              },
                            ),
                          )
                        : null,
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 0,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.2,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              // Members list
              Expanded(
                child: FutureBuilder<List<Map<String, String>>>(
                  future: _membersFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: VibeLoading(
                          size: 40,
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                          segments: 12,
                        ),
                      );
                    }
                    final allMembers =
                        List<Map<String, String>>.from(snapshot.data!)
                          ..sort((a, b) {
                            if (a['role'] == 'Host') return -1;
                            if (b['role'] == 'Host') return 1;
                            return (a['name'] ?? '').compareTo(b['name'] ?? '');
                          });

                    final members = _query.isEmpty
                        ? allMembers
                        : allMembers
                              .where(
                                (m) => (m['name'] ?? '').toLowerCase().contains(
                                  _query,
                                ),
                              )
                              .toList();

                    if (members.isEmpty) {
                      return VibeEmptyState(
                        title: _query.isEmpty
                            ? 'No members yet'
                            : 'No members found',
                        message: _query.isEmpty
                            ? 'Participants will appear here as soon as they join.'
                            : 'Try searching with another name.',
                        icon: Icons.person_search_rounded,
                        compact: true,
                      );
                    }

                    final currentUserId = ProfileState.notifier.value.id;

                    return ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        final isHost = member['role'] == 'Host';
                        final isMe = member['id'] == currentUserId;

                        return _MemberTile(
                          member: member,
                          isHost: isHost,
                          isMe: isMe,
                          isDark: isDark,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Member Tile ──────────────────────────────────────────────────────────────
class _MemberTile extends StatefulWidget {
  const _MemberTile({
    required this.member,
    required this.isHost,
    required this.isMe,
    required this.isDark,
  });
  final Map<String, String> member;
  final bool isHost;
  final bool isMe;
  final bool isDark;

  @override
  State<_MemberTile> createState() => _MemberTileState();
}

class _MemberTileState extends State<_MemberTile> {
  bool _requested = false;

  Future<void> _sendFriendRequest(BuildContext context, String userId) async {
    if (userId.isEmpty) return;
    try {
      await sl<UserApiService>().requestFriend(userId);
      if (mounted) setState(() => _requested = true);
      sl<SignalRService>().emitLocalChange('friendship', {'userId': userId});
      if (context.mounted) VibeSnackBar.success(context, 'Friend request sent');
    } catch (e) {
      if (context.mounted) VibeFeedback.apiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (widget.member['friendshipStatus'] ?? '').toLowerCase();
    final isFriend = status == 'accepted' || status == 'friend';
    final isPending =
        _requested || status == 'requested' || status == 'pending';
    final canAddFriend = !widget.isMe && !isFriend && !isPending;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E2A3A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDark ? Colors.white10 : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                final id = widget.member['id'];
                if (id != null && id.isNotEmpty) {
                  context.router.push(PublicProfileRoute(userId: id));
                }
              },
              child: Row(
                children: [
                  Stack(
                    children: [
                      VibeAvatar(
                        imageUrl: widget.member['avatarUrl'],
                        name: widget.member['name'],
                        size: 48,
                        showBorder: false,
                      ),
                      if (widget.isHost)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget.isDark
                                    ? const Color(0xFF1C2233)
                                    : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              color: Colors.white,
                              size: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.member['name'] ?? 'Member',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: widget.isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.isHost
                              ? 'Host ★'
                              : (widget.member['role'] ?? 'Participant'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: widget.isHost
                                ? AppColors.primary
                                : AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!widget.isMe)
            GestureDetector(
              onTap: canAddFriend
                  ? () {
                      HapticFeedback.selectionClick();
                      _sendFriendRequest(
                        context,
                        (widget.member['id'] ?? '').toString(),
                      );
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: canAddFriend
                      ? AppColors.primarySurface
                      : AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isFriend ? 'Friend' : (isPending ? 'Requested' : 'Add'),
                  style: TextStyle(
                    color: canAddFriend
                        ? AppColors.primary
                        : AppColors.textHint,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Loading Shimmer ──────────────────────────────────────────────────────────
class _LoadingShimmer extends StatefulWidget {
  const _LoadingShimmer();

  @override
  State<_LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<_LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Column(
        children: [
          Container(height: 340, color: const Color(0xFFE2E8F0)),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: List.generate(
                4,
                (i) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF2F7),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
