import 'dart:async';
import 'dart:ui';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/profile_state.dart';
import '../../../../injection/injection_container.dart';
import '../../data/services/event_api_service.dart';
import '../../domain/entities/event.dart';
import '../../../../router/app_router.gr.dart';
import '../../../../core/services/signalr_service.dart';
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

  String _safeImage(
    String? url, {
    String fallback = 'https://picsum.photos/900/600',
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

    _statusSubscription = sl<SignalRService>().eventStatusStream.listen((data) {
      final eventId = (data['eventId'] ?? data['EventId'])?.toString();
      if (eventId == widget.eventId) {
        _cubit.loadEvent(widget.eventId);
      }
    });
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _cubit.close();
    _fabAnim.dispose();
    super.dispose();
  }

  bool _isHost(Event event) {
    final profile = ProfileState.notifier.value;
    if (event.hostId.isEmpty || profile.id.isEmpty) return false;
    return event.hostId.toLowerCase() == profile.id.toLowerCase();
  }

  Future<void> _copyJoinLink(Event event) async {
    final link = sl<EventApiService>().buildJoinRequestLink(event.id);
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.link_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Invite link copied!',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 2),
      ),
    );
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
    await context.router.push(ManageEventRoute(eventId: event.id));
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
      if (mounted) {
        context.router.popUntilRoot();
      }
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
                    );
                  }

                  return Stack(
                    children: [
                      CustomScrollView(
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

  Widget _buildError(String message) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(Event event) {
    final imageUrl = event.photoUrls.isNotEmpty
        ? _safeImage(event.photoUrls.first)
        : 'https://picsum.photos/seed/${event.id}/900/500';

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: _GlassButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => context.router.maybePop(),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: _GlassButton(
            icon: Icons.ios_share_rounded,
            onTap: () => _copyJoinLink(event),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context2, err, trace) => Container(
                color: AppColors.bgSecondary,
                child: const Icon(
                  Icons.image_not_supported,
                  color: AppColors.textHint,
                  size: 40,
                ),
              ),
            ),
            // Gradient overlay
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.45, 1.0],
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
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Event event) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 160),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Host card
            _buildHostCard(event),
            const SizedBox(height: 20),

            // AI Match
            if (event.matchScore > 0) ...[
              _buildAIMatchCard(event),
              const SizedBox(height: 20),
            ],

            // Info cards row
            _buildInfoRow(event),
            const SizedBox(height: 20),

            // The Circle (members)
            _buildCircleCard(event),
            const SizedBox(height: 20),

            // About
            _buildAboutSection(event),
          ],
        ),
      ),
    );
  }

  Widget _buildHostCard(Event event) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.bgSecondary,
                backgroundImage: NetworkImage(
                  _safeImage(
                    event.hostAvatar,
                    fallback: 'https://i.pravatar.cc/100?img=11',
                  ),
                ),
                onBackgroundImageError: (o, s) {},
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
                  'Hosted by',
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.hostName.isNotEmpty
                      ? event.hostName
                      : 'Unknown Vibe Caster',
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (!_isHost(event))
            GestureDetector(
              onTap: () => HapticFeedback.selectionClick(),
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
                  'Follow',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAIMatchCard(Event event) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
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
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontSize: 14,
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
                          fontSize: 15,
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

  Widget _buildInfoRow(Event event) {
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            icon: Icons.calendar_month_rounded,
            label: 'Date',
            value:
                '${event.startDateTime.day}/${event.startDateTime.month}/${event.startDateTime.year}',
            sub:
                '${event.startDateTime.hour}:${event.startDateTime.minute.toString().padLeft(2, '0')}',
            color: const Color(0xFF5856D6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoCard(
            icon: Icons.location_on_rounded,
            label: 'Location',
            value: event.location.name.isNotEmpty ? event.location.name : 'TBD',
            sub: event.location.address,
            color: AppColors.error,
            onTap: () => HapticFeedback.selectionClick(),
          ),
        ),
      ],
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
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.bgSecondary,
                                  backgroundImage: NetworkImage(
                                    _safeImage(
                                      e.value,
                                      fallback:
                                          'https://i.pravatar.cc/100?img=${e.key + 10}',
                                    ),
                                  ),
                                  onBackgroundImageError: (o, s) {},
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

  Widget _buildAboutSection(Event event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About this vibe',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            event.description.isNotEmpty
                ? event.description
                : 'Come join us and have a great time! Looking forward to meeting new people who match this vibe.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.65,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (_isHost(event)) ...[
          const SizedBox(height: 14),
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
                        onPressed: isJoining || event.isPending
                            ? null
                            : (_isHost(event)
                                  ? () => _deleteEvent(event)
                                  : () => _cubit.toggleJoinLeave()),
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
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isHost(event)
                                    ? '✗  Delete Vibe'
                                    : (event.isJoined
                                          ? '✗  Leave Vibe'
                                          : (event.isPending
                                                ? '⏳  Pending Approval'
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
}

// ─── Glass Button ──────────────────────────────────────────────────────────────
class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            ),
            child: Icon(icon, color: AppColors.secondary, size: 18),
          ),
        ),
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

// ─── Info Card ────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.sub,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final String? sub;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textHint,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.secondary,
              ),
            ),
            if (sub != null && sub!.isNotEmpty)
              Text(
                sub!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
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
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.secondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search members…',
                      hintStyle: TextStyle(
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppColors.textHint,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
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
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2.5,
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
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_search_rounded,
                              size: 48,
                              color: AppColors.textHint.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'No members found',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
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
class _MemberTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHost
              ? AppColors.primary.withValues(alpha: 0.3)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.borderLight),
          width: isHost ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.bgSecondary,
                backgroundImage: NetworkImage(
                  member['avatarUrl'] ?? 'https://i.pravatar.cc/100?img=20',
                ),
                onBackgroundImageError: (o, s) {},
              ),
              if (isHost)
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
                        color: isDark ? const Color(0xFF1C2233) : Colors.white,
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
                  member['name'] ?? 'Member',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isHost ? 'Host ★' : (member['role'] ?? 'Participant'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isHost ? AppColors.primary : AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          if (!isMe)
            GestureDetector(
              onTap: () => HapticFeedback.selectionClick(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Follow',
                  style: TextStyle(
                    color: AppColors.primary,
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
          Container(height: 340, color: AppColors.bgSecondary),
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
                    color: AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(20),
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
