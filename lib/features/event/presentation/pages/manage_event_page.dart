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
import '../../../../injection/injection_container.dart';
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
  late Future<List<Map<String, String>>> _participantsFuture;
  bool _isReadOnly = false;
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
    _participantsFuture = sl<EventApiService>().getEventParticipants(
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member?'),
        content: const Text(
          'Are you sure you want to remove this participant from the event?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      await sl<EventApiService>().removeParticipant(widget.eventId, userId);
      sl<SignalRService>().emitLocalChange('event', {
        'eventId': widget.eventId,
      });
      _refresh();
    }
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
    return FutureBuilder<List<Map<String, String>>>(
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
            padding: EdgeInsets.fromLTRB(20, 145, 20, 20),
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
            padding: EdgeInsets.fromLTRB(20, 145, 20, 20),
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

  Widget _buildMemberCard(Map<String, String> member) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHost = member['role'] == 'Host';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171D2A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Row(
        children: [
          VibeAvatar(
            imageUrl: member['avatarUrl'],
            name: member['name'],
            size: 48,
            showBorder: false,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['name'] ?? 'Member',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member['role'] ?? 'Participant',
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (!isHost && !_isReadOnly)
            IconButton(
              onPressed: () => _removeMember(member['id'] ?? ''),
              icon: const Icon(
                Icons.person_remove_rounded,
                color: AppColors.error,
                size: 20,
              ),
            ),
        ],
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1F2E) : Colors.white;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.borderLight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              constraints: const BoxConstraints(
                maxHeight: 45,
              ),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
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
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
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
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        leading: VibeAvatar(
                          imageUrl: user['avatarUrl'],
                          name: user['name'],
                          size: 48,
                          showBorder: true,
                          borderColor: AppColors.primary.withValues(alpha: 0.2),
                          borderWidth: 2,
                        ),
                        title: Text(
                          user['name'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.secondary,
                          ),
                        ),
                        subtitle: Text(
                          user['email'] ?? '',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : AppColors.textHint,
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
                                  : (isAlreadyInvited ? 'Invited' : 'Invite'),
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
    );
  }
}
