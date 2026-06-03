// lib/features/event/presentation/pages/manage_event_page.dart
import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/vibe_button.dart';
import '../../../../core/widgets/vibe_empty_state.dart';
import '../../../../core/widgets/vibe_header.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../core/widgets/snackbar_service.dart';
import '../../../../core/services/signalr_service.dart';
import '../../../../core/widgets/vibe_confirm_dialog.dart';
import '../../../../injection/injection_container.dart';
import '../../../../router/app_router.gr.dart';
import '../../../find_in_crowd/data/services/find_in_crowd_api_service.dart';
import '../../../find_in_crowd/domain/entities/finder_models.dart';
import '../../../trust/data/services/reputation_api_service.dart';
import '../../../trust/domain/entities/user_trust.dart';
import '../../../trust/domain/services/reputation_service.dart';
import '../../../trust/presentation/widgets/host_review_form.dart';
import '../../data/services/event_api_service.dart';
import '../../domain/entities/event.dart';

@RoutePage()
class ManageEventPage extends StatefulWidget {
  const ManageEventPage({super.key, required this.eventId});

  final String eventId;

  @override
  State<ManageEventPage> createState() => _ManageEventPageState();
}

class _ManageEventPageState extends State<ManageEventPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  late Future<List<Map<String, String>>> _requestsFuture;
  late Future<List<EventFinderMember>> _participantsFuture;
  bool _isReadOnly = false;
  final Set<String> _expandedParticipantIds = {};
  final Map<String, Future<UserTrust>> _trustFutures = {};
  StreamSubscription<Map<String, dynamic>>? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _realtimeSubscription = sl<SignalRService>().dataChangeStream.listen((
      data,
    ) {
      final eventId = (data['eventId'] ?? data['EventId'])?.toString();
      if (eventId == null || eventId == widget.eventId) _refresh();
    });
  }

  void _loadData() {
    _trustFutures.clear();
    sl<EventApiService>().getEventDetail(widget.eventId).then((event) {
      if (!mounted) return;
      final ended = event.endDateTime?.isBefore(DateTime.now()) ?? false;
      setState(() {
        _isReadOnly =
            ended ||
            event.status == EventStatus.completed ||
            event.status == EventStatus.cancelled;
      });
    });
    _requestsFuture = sl<EventApiService>().getPendingJoinRequests(
      widget.eventId,
    );
    _participantsFuture = sl<FindInCrowdApiService>().getEventMembers(
      widget.eventId,
    );
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _loadData();
    });
  }

  Future<void> _approve(String requestId) async {
    if (_isReadOnly) return;
    HapticFeedback.mediumImpact();
    await sl<EventApiService>().approveJoinRequest(widget.eventId, requestId);
    sl<SignalRService>().emitLocalChange('event', {'eventId': widget.eventId});
    _refresh();
  }

  Future<void> _reject(String requestId) async {
    if (_isReadOnly) return;
    HapticFeedback.lightImpact();
    await sl<EventApiService>().rejectJoinRequest(widget.eventId, requestId);
    sl<SignalRService>().emitLocalChange('event', {'eventId': widget.eventId});
    _refresh();
  }

  Future<void> _removeMember(String userId) async {
    if (_isReadOnly) return;
    final confirmed = await showVibeConfirmDialog(
      context: context,
      title: 'Remove Member?',
      message:
          'Are you sure you want to remove this participant from the event?',
      confirmLabel: 'Remove',
      cancelLabel: 'Cancel',
      icon: Icons.person_remove_rounded,
      isDestructive: true,
    );

    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      await sl<EventApiService>().removeParticipant(widget.eventId, userId);
      sl<SignalRService>().emitLocalChange('event', {
        'eventId': widget.eventId,
      });
      _expandedParticipantIds.remove(userId);
      _trustFutures.remove(userId);
      _refresh();
    }
  }

  Future<UserTrust> _loadMemberTrust(EventFinderMember member) {
    final userId = member.userId;
    return _trustFutures.putIfAbsent(
      userId,
      () => sl<ReputationApiService>().getUserTrust(
        userId,
        userName: member.fullName,
        avatarUrl: member.avatarUrl,
      ),
    );
  }

  void _showInviteDialog() {
    if (_isReadOnly) {
      VibeSnackBar.info(context, 'This event is done. Members are read-only.');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _InviteBottomSheet(eventId: widget.eventId, onInvite: _refresh),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0E121A) : const Color(0xFFF5F7FF);

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: VibeHeader(
        title: 'Manage Event',
        subtitle: 'Participants & Requests',
        actions: _isReadOnly
            ? null
            : [
                VibeHeaderButton(
                  icon: Icons.person_add_rounded,
                  onTap: _showInviteDialog,
                  isDark: isDark,
                  color: AppColors.primary,
                ),
              ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFF1F4F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                padding: const EdgeInsets.all(4),
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                splashFactory: NoSplash.splashFactory,
                labelColor: Colors.white,
                unselectedLabelColor: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textHint,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'Participants'),
                  Tab(text: 'Requests'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildParticipantsTab(), _buildRequestsTab()],
      ),
    );
  }

  Widget _buildParticipantsTab() {
    return FutureBuilder<List<EventFinderMember>>(
      future: _participantsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final members = snapshot.data ?? [];
        if (members.isEmpty) {
          return _buildEmptyState(
            'No participants yet',
            Icons.group_off_rounded,
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.viewPaddingOf(context).top +
                  VibeHeader.headerHeight +
                  60 +
                  20,
              20,
              20,
            ),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return _buildMemberCard(member);
            },
          ),
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    return FutureBuilder<List<Map<String, String>>>(
      future: _requestsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return _buildEmptyState(
            'No pending requests',
            Icons.mark_email_read_rounded,
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.viewPaddingOf(context).top +
                  VibeHeader.headerHeight +
                  60 +
                  20,
              20,
              20,
            ),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _buildRequestCard(request);
            },
          ),
        );
      },
    );
  }

  Widget _buildMemberCard(EventFinderMember member) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHost = member.role == 'Host';
    final memberId = member.userId;
    final isExpanded = _expandedParticipantIds.contains(memberId);
    final roleLabel = member.role ?? (isHost ? 'Host' : 'Participant');

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF171D2A) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isExpanded
                ? AppColors.primary.withValues(alpha: 0.18)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03)),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: const Color(0xFF1E293B).withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                if (memberId.isEmpty) return;
                HapticFeedback.selectionClick();
                setState(() {
                  if (isExpanded) {
                    _expandedParticipantIds.remove(memberId);
                  } else {
                    _expandedParticipantIds.add(memberId);
                    if (!isHost) _loadMemberTrust(member);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    VibeAvatar(
                      imageUrl: member.avatarUrl,
                      name: member.fullName,
                      size: 52,
                      showBorder: true,
                      borderColor: isHost
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                          : AppColors.primary.withValues(alpha: 0.18),
                      borderWidth: 2,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : AppColors.secondary,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${member.statusLabel} - $roleLabel',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textHint,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isHost)
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF59E0B,
                          ).withValues(alpha: isDark ? 0.16 : 0.1),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFF59E0B),
                          size: 20,
                        ),
                      )
                    else ...[
                      if (!_isReadOnly)
                        IconButton(
                          onPressed: () => showHostReviewForm(
                            context,
                            userId: memberId,
                            userName: member.fullName,
                            userAvatarUrl: member.avatarUrl,
                            onSubmit: (stars, attended) {},
                          ),
                          tooltip: 'Review',
                          icon: const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFF59E0B),
                            size: 21,
                          ),
                        ),
                      if (!_isReadOnly)
                        IconButton(
                          onPressed: () => _removeMember(memberId),
                          tooltip: 'Remove from event',
                          icon: const Icon(
                            Icons.person_remove_rounded,
                            color: AppColors.error,
                            size: 21,
                          ),
                        ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: isDark ? Colors.white38 : AppColors.textHint,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (isExpanded && !isHost)
              FutureBuilder<UserTrust>(
                future: _loadMemberTrust(member),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _MemberTrustLoading();
                  }
                  if (snapshot.hasError || snapshot.data == null) {
                    return _MemberTrustError(
                      isDark: isDark,
                      onRetry: () {
                        setState(() {
                          _trustFutures.remove(memberId);
                          _loadMemberTrust(member);
                        });
                      },
                    );
                  }
                  return _MemberTrustPanel(trust: snapshot.data!);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, String> request) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171D2A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              VibeAvatar(
                imageUrl: request['avatarUrl'],
                name: request['name'],
                size: 44,
                showBorder: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request['name'] ?? 'Guest',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'wants to join',
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (request['message'] != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                request['message']!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (!_isReadOnly)
            Row(
              children: [
                Expanded(
                  child: VibeButton(
                    label: 'Reject',
                    onPressed: () => _reject(request['id'] ?? ''),
                    type: VibeButtonType.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: VibeButton(
                    label: 'Approve',
                    onPressed: () => _approve(request['id'] ?? ''),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: VibeEmptyState(
          title: message,
          message: message == 'No pending requests'
              ? 'New join requests will appear here in realtime.'
              : 'Participants will appear here as soon as they join.',
          icon: icon,
        ),
      ),
    );
  }
}

class _MemberTrustPanel extends StatelessWidget {
  const _MemberTrustPanel({required this.trust});

  final UserTrust trust;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final levelData = ReputationService.getLevel(trust.score);
    final attendance = (trust.attendanceRate * 100).round().clamp(0, 100);
    final noShowsLast30Days = ReputationService.getNoShowsLast30Days(
      trust.history,
    );
    final noShowValue = noShowsLast30Days > 0
        ? noShowsLast30Days
        : trust.noShows;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : levelData.color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: levelData.color.withValues(alpha: 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: levelData.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: levelData.color.withValues(alpha: 0.22),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${trust.score}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      Text(
                        'pts',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.86),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            levelData.emoji,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              levelData.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: levelData.color,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        trust.score < 40
                            ? 'Cần cân nhắc khi duyệt tham gia sự kiện.'
                            : 'Thông tin uy tín được đồng bộ từ hệ thống.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TrustMetricChip(
                  icon: Icons.check_circle_outline_rounded,
                  value: '$attendance%',
                  label: 'tham gia',
                  color: const Color(0xFF22C55E),
                ),
                _TrustMetricChip(
                  icon: Icons.event_available_rounded,
                  value: '${trust.onTimeCheckins}',
                  label: 'check-in',
                  color: const Color(0xFF2563EB),
                ),
                _TrustMetricChip(
                  icon: Icons.warning_amber_rounded,
                  value: '$noShowValue',
                  label: 'leo cây',
                  color: const Color(0xFFEF4444),
                ),
                _TrustMetricChip(
                  icon: Icons.groups_rounded,
                  value: '${trust.eventsJoined}',
                  label: 'sự kiện',
                  color: const Color(0xFF8B5CF6),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustMetricChip extends StatelessWidget {
  const _TrustMetricChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 132,
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.secondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textHint,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
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

class _MemberTrustLoading extends StatelessWidget {
  const _MemberTrustLoading();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        height: 78,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      ),
    );
  }
}

class _MemberTrustError extends StatelessWidget {
  const _MemberTrustError({required this.isDark, required this.onRetry});

  final bool isDark;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.16),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFEF4444),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Không tải được uy tín',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

class _InviteBottomSheet extends StatefulWidget {
  const _InviteBottomSheet({required this.eventId, required this.onInvite});
  final String eventId;
  final VoidCallback onInvite;

  @override
  State<_InviteBottomSheet> createState() => _InviteBottomSheetState();
}

class _InviteBottomSheetState extends State<_InviteBottomSheet> {
  final _searchCtrl = TextEditingController();
  List<Map<String, String>> _results = [];
  bool _isLoading = false;
  final Set<String> _invitedIds = {};
  final Set<String> _participantIds = {};

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    final participants = await sl<EventApiService>().getEventParticipants(
      widget.eventId,
    );
    if (!mounted) return;
    setState(() {
      _participantIds
        ..clear()
        ..addAll(
          participants
              .map((member) => (member['id'] ?? '').toLowerCase())
              .where((id) => id.isNotEmpty),
        );
    });
  }

  Future<void> _search() async {
    final query = _searchCtrl.text.trim();
    if (query.length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isLoading = true);
    final results = await sl<EventApiService>().searchUsers(
      query,
      eventId: widget.eventId,
    );
    if (mounted) {
      setState(() {
        _results = results
            .where(
              (user) =>
                  !_participantIds.contains((user['id'] ?? '').toLowerCase()),
            )
            .toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _invite(String userId) async {
    HapticFeedback.mediumImpact();
    try {
      await sl<EventApiService>().inviteUser(widget.eventId, userId);
      setState(() => _invitedIds.add(userId.toLowerCase()));
      sl<SignalRService>().emitLocalChange('event', {
        'eventId': widget.eventId,
      });
      widget.onInvite();
      if (mounted) {
        VibeFeedback.apiSuccess(context, 'User invited successfully!');
      }
    } catch (e) {
      if (mounted) {
        VibeFeedback.apiError(context, e);
      }
    }
  }

  Future<void> _openUserProfile(String userId) async {
    if (userId.isEmpty) return;
    HapticFeedback.selectionClick();
    final router = context.router;
    Navigator.of(context).pop();
    await Future<void>.delayed(const Duration(milliseconds: 220));
    router.push(PublicProfileRoute(userId: userId));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1F2E) : Colors.white;
    final mediaQuery = MediaQuery.of(context);
    final availableHeight =
        mediaQuery.size.height -
        mediaQuery.viewPadding.top -
        mediaQuery.viewInsets.bottom -
        12;
    final maxSheetHeight = availableHeight < mediaQuery.size.height * 0.86
        ? availableHeight
        : mediaQuery.size.height * 0.86;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: isDark ? Colors.white10 : AppColors.borderLight,
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            24 + mediaQuery.viewPadding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Invite Friends',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.secondary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchCtrl,
                onChanged: (_) => _search(),
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
                  hintText: 'Search by name or email...',
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.darkTextHint : AppColors.textHint,
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
                              _search();
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
              const SizedBox(height: 24),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _results.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: VibeEmptyState(
                            title: _searchCtrl.text.isEmpty
                                ? 'Search users'
                                : 'No users found',
                            message: _searchCtrl.text.isEmpty
                                ? 'Enter a name or email to find people to invite.'
                                : 'Try a different name or email.',
                            icon: _searchCtrl.text.isEmpty
                                ? Icons.person_search_rounded
                                : Icons.search_off_rounded,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, _) => Divider(
                          color: isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.03),
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final user = _results[index];
                          final userId = user['id'] ?? '';
                          final inviteStatus = (user['inviteStatus'] ?? '')
                              .toLowerCase();
                          final isParticipant = _participantIds.contains(
                            userId.toLowerCase(),
                          );
                          final isAlreadyInvited =
                              isParticipant ||
                              _invitedIds.contains(userId.toLowerCase()) ||
                              inviteStatus == 'invited' ||
                              inviteStatus == 'pending' ||
                              inviteStatus == 'joined' ||
                              inviteStatus == 'accepted';
                          return ListTile(
                            onTap: () => _openUserProfile(userId),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            leading: VibeAvatar(
                              imageUrl: user['avatarUrl'],
                              name: user['name'],
                              size: 48,
                              showBorder: true,
                              borderColor: AppColors.primary.withValues(
                                alpha: 0.2,
                              ),
                              borderWidth: 2,
                            ),
                            title: Text(
                              user['name'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.secondary,
                              ),
                            ),
                            subtitle: Text(
                              user['email'] ?? '',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white54
                                    : AppColors.textHint,
                                fontSize: 12,
                              ),
                            ),
                            trailing: SizedBox(
                              width: 80,
                              height: 32,
                              child: ElevatedButton(
                                onPressed: isAlreadyInvited
                                    ? null
                                    : () => _invite(userId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isAlreadyInvited
                                      ? Colors.grey.withValues(alpha: 0.1)
                                      : AppColors.primary,
                                  foregroundColor: isAlreadyInvited
                                      ? Colors.grey
                                      : Colors.white,
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  inviteStatus == 'joined' ||
                                          isParticipant ||
                                          inviteStatus == 'accepted'
                                      ? 'Joined'
                                      : (isAlreadyInvited
                                            ? 'Invited'
                                            : 'Invite'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
