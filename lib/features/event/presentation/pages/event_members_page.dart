import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../injection/injection_container.dart';
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

  Widget _membersTab() {
    return FutureBuilder<List<Map<String, String>>>(
      future: sl<EventApiService>().getEventParticipants(widget.eventId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = snapshot.data!;
        if (members.isEmpty) {
          return const Center(child: Text('No members yet'));
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
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(member['avatarUrl']!),
                ),
                title: Text(
                  member['name'] ?? 'Member',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(member['role'] ?? 'Participant'),
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
            child: Text(
              'No pending requests',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
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
                  CircleAvatar(
                    backgroundImage: NetworkImage(request['avatarUrl']!),
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
