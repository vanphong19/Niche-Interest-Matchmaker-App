import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/vibe_empty_state.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../injection/injection_container.dart';
import '../../../../router/app_router.gr.dart';
import '../../../find_in_crowd/data/services/find_in_crowd_api_service.dart';
import '../../../find_in_crowd/domain/entities/finder_models.dart';
import '../../data/services/event_api_service.dart';

class EventMembersPage extends StatefulWidget {
  const EventMembersPage({
    super.key,
    required this.eventId,
    this.isHost = false,
  });

  final String eventId;
  final bool isHost;

  @override
  State<EventMembersPage> createState() => _EventMembersPageState();
}

class _EventMembersPageState extends State<EventMembersPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.isHost ? 2 : 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _approve(String requestId) async {
    await sl<EventApiService>().approveJoinRequest(widget.eventId, requestId);
    if (mounted) setState(() {});
  }

  Future<void> _reject(String requestId) async {
    await sl<EventApiService>().rejectJoinRequest(widget.eventId, requestId);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0E121A)
          : const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: const Text(
          'Event Members',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        bottom: widget.isHost
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Members'),
                  Tab(text: 'Requests'),
                ],
              )
            : null,
      ),
      body: widget.isHost
          ? TabBarView(
              controller: _tabController,
              children: [_membersTab(), _requestsTab()],
            )
          : _membersTab(),
    );
  }

  void _openFinder(EventFinderMember member) {
    if (member.canResume) {
      context.router.push(
        FinderRadarRoute(sessionId: member.activeFinderSessionId!),
      );
      return;
    }
    context.router.push(
      FinderStartRoute(eventId: widget.eventId, partnerId: member.userId),
    );
  }

  Widget _membersTab() {
    return FutureBuilder<List<EventFinderMember>>(
      future: sl<FindInCrowdApiService>().getEventMembers(widget.eventId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = snapshot.data!;
        if (members.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: VibeEmptyState(
                title: 'No members yet',
                message: 'Participants will appear here as soon as they join.',
                icon: Icons.group_outlined,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: VibeAvatar(
                  imageUrl: member.avatarUrl,
                  name: member.fullName,
                  size: 40,
                ),
                title: Text(
                  member.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(member.statusLabel),
                trailing: SizedBox(
                  width: 112,
                  child: FilledButton.tonal(
                    onPressed: member.canFind || member.canResume
                        ? () => _openFinder(member)
                        : null,
                    child: Text(member.actionLabel),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _requestsTab() {
    return FutureBuilder<List<Map<String, String>>>(
      future: sl<EventApiService>().getPendingJoinRequests(widget.eventId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data!;
        if (requests.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: VibeEmptyState(
                title: 'No pending requests',
                message: 'New join requests will appear here in realtime.',
                icon: Icons.mark_email_unread_outlined,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  VibeAvatar(
                    imageUrl: request['avatarUrl'],
                    name: request['name'],
                    size: 40,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request['name'] ?? 'Guest',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          request['message'] ?? 'Wants to join your event',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: () => _reject(request['id'] ?? ''),
                    child: const Text('Reject'),
                  ),
                  FilledButton(
                    onPressed: () => _approve(request['id'] ?? ''),
                    child: const Text('Approve'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
