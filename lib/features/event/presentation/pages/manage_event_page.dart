// lib/features/event/presentation/pages/manage_event_page.dart
import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/vibe_button.dart';
import '../../../../core/widgets/vibe_header.dart';
import '../../../../injection/injection_container.dart';
import '../../data/services/event_api_service.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    _requestsFuture = sl<EventApiService>().getPendingJoinRequests(
      widget.eventId,
    );
    _participantsFuture = sl<EventApiService>().getEventParticipants(
      widget.eventId,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _loadData();
    });
  }

  Future<void> _approve(String requestId) async {
    HapticFeedback.mediumImpact();
    await sl<EventApiService>().approveJoinRequest(widget.eventId, requestId);
    _refresh();
  }

  Future<void> _reject(String requestId) async {
    HapticFeedback.lightImpact();
    await sl<EventApiService>().rejectJoinRequest(widget.eventId, requestId);
    _refresh();
  }

  Future<void> _removeMember(String userId) async {
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
      _refresh();
    }
  }

  void _showInviteDialog() {
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
        actions: [
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
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(
              member['avatarUrl'] ?? 'https://i.pravatar.cc/100',
            ),
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
          if (!isHost)
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
              CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(
                  request['avatarUrl'] ?? 'https://i.pravatar.cc/100',
                ),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: AppColors.textHint.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textHint,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

  Future<void> _search() async {
    final query = _searchCtrl.text.trim();
    if (query.length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isLoading = true);
    final results = await sl<EventApiService>().searchUsers(query);
    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _invite(String userId) async {
    HapticFeedback.mediumImpact();
    try {
      await sl<EventApiService>().inviteUser(widget.eventId, userId);
      setState(() => _invitedIds.add(userId));
      widget.onInvite();
      if (mounted) {
        _showLuxuryToast(context, 'User invited successfully!');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to invite user: $e'),
            backgroundColor: AppColors.error,
          ),
        );
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
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
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.secondary,
            ),
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : AppColors.textHint,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: isDark ? Colors.white38 : AppColors.textHint,
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.bgSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onChanged: (_) => _search(),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchCtrl.text.isEmpty
                              ? Icons.person_search_rounded
                              : Icons.search_off_rounded,
                          size: 48,
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchCtrl.text.isEmpty
                              ? 'Enter a name or email to start'
                              : 'No users found matching your search',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.white38 : AppColors.textHint,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => Divider(
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.03),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final user = _results[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        leading: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: isDark
                                ? Colors.white10
                                : AppColors.bgSecondary,
                            backgroundImage:
                                (user['avatarUrl']?.isNotEmpty ?? false)
                                ? NetworkImage(user['avatarUrl']!)
                                : null,
                            child: (user['avatarUrl']?.isEmpty ?? true)
                                ? Icon(
                                    Icons.person_rounded,
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.black12,
                                  )
                                : null,
                            onBackgroundImageError: (o, s) {},
                          ),
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
                            onPressed: _invitedIds.contains(user['id'])
                                ? null
                                : () => _invite(user['id']!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _invitedIds.contains(user['id'])
                                  ? Colors.grey.withValues(alpha: 0.1)
                                  : AppColors.primary,
                              foregroundColor: _invitedIds.contains(user['id'])
                                  ? Colors.grey
                                  : Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              _invitedIds.contains(user['id'])
                                  ? 'Invited'
                                  : 'Invite',
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

  void _showLuxuryToast(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => _LuxuryToastWidget(message: message),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) entry.remove();
    });
  }
}

class _LuxuryToastWidget extends StatefulWidget {
  final String message;
  const _LuxuryToastWidget({required this.message});

  @override
  State<_LuxuryToastWidget> createState() => _LuxuryToastWidgetState();
}

class _LuxuryToastWidgetState extends State<_LuxuryToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _offset = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 20,
      right: 20,
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _offset,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981), // Emerald Green
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
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
