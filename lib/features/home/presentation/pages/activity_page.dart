import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/snackbar_service.dart';
import '../../../../core/widgets/vibe_empty_state.dart';
import '../../../../core/services/signalr_service.dart';
import '../../../../injection/injection_container.dart';
import '../../../../router/app_router.gr.dart';
import '../../../checkin/presentation/models/checkin_event_details.dart';
import '../../../checkin/presentation/pages/checkin_detail_page.dart';
import '../../../profile/data/services/user_api_service.dart';
import '../../../event/domain/entities/event.dart';
import '../../../event/presentation/bloc/event_bloc.dart';

@RoutePage()
class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage>
    with SingleTickerProviderStateMixin {
  late final EventBloc _eventBloc;
  late final TabController _tabController;
  StreamSubscription<Map<String, dynamic>>? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    _eventBloc = sl<EventBloc>();
    _eventBloc.add(LoadMyEvents());
    _tabController = TabController(length: 4, vsync: this);
    _realtimeSubscription = sl<SignalRService>().dataChangeStream.listen((_) {
      _eventBloc.add(LoadMyEvents());
    });
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _eventBloc.close();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _eventBloc,
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkBgPrimary
            : AppColors.bgSecondary,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'My Activity',
            style: TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.w900,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Open check-in',
              onPressed: () {
                final event = _firstCheckinCandidate(_eventBloc.state.joined);
                if (event == null) {
                  VibeSnackBar.info(
                    context,
                    'Join an active vibe before checking in.',
                  );
                  return;
                }
                _openCheckin(event);
              },
              icon: const Icon(
                Icons.verified_user_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textHint,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Hosted'),
              Tab(text: 'Joined'),
              Tab(text: 'Past'),
              Tab(text: 'Notifications'),
            ],
          ),
        ),
        body: BlocBuilder<EventBloc, EventState>(
          builder: (context, state) {
            if (state.isLoading &&
                state.hosting.isEmpty &&
                state.joined.isEmpty &&
                state.past.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildEventList(state.hosting, isHost: true),
                _buildEventList(state.joined, isHost: false),
                _buildEventList(state.past, isHost: false, isPast: true),
                _NotificationsTab(
                  onChanged: () => _eventBloc.add(LoadMyEvents()),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventList(
    List<Event> events, {
    required bool isHost,
    bool isPast = false,
  }) {
    if (events.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: VibeEmptyState(
            title: 'No events here yet',
            message:
                'Events will appear here as soon as your activity changes.',
            icon: Icons.event_busy_rounded,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(
                          event.photoUrls.isNotEmpty
                              ? event.photoUrls.first
                              : 'https://api-prod-minimal-v700.pages.dev/assets/images/cover/cover-${(event.id.hashCode % 20) + 1}.webp',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${event.startDateTime.day}/${event.startDateTime.month} • ${event.location.name}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.borderLight, height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isPast ? 'Ended' : 'Starts in 2 days',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isPast ? AppColors.textHint : AppColors.info,
                      fontSize: 13,
                    ),
                  ),
                  Row(
                    children: [
                      if (isHost && !isPast) ...[
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Edit',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                      ElevatedButton(
                        onPressed: () {
                          if (!isHost && !isPast) {
                            _openCheckin(event);
                            return;
                          }

                          context.router.push(
                            EventDetailRoute(eventId: event.id),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPast
                              ? AppColors.bgSecondary
                              : AppColors.primary,
                          foregroundColor: isPast
                              ? AppColors.secondary
                              : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isPast
                              ? 'Rate Experience'
                              : (isHost ? 'Manage' : 'Check In'),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Event? _firstCheckinCandidate(List<Event> events) {
    for (final event in events) {
      if (event.status == EventStatus.active) return event;
    }
    return events.isNotEmpty ? events.first : null;
  }

  void _openCheckin(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CheckinDetailPage(
          eventDetails: CheckinEventDetails.fromEvent(event),
        ),
      ),
    );
  }
}

class _NotificationsTab extends StatefulWidget {
  const _NotificationsTab({required this.onChanged});
  final VoidCallback onChanged;

  @override
  State<_NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<_NotificationsTab> {
  late Future<List<Map<String, dynamic>>> _future;
  StreamSubscription<Map<String, dynamic>>? _subscription;

  @override
  void initState() {
    super.initState();
    _future = sl<UserApiService>().getNotifications();
    _subscription = sl<SignalRService>().notificationStream.listen((_) {
      if (mounted) _refresh();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = sl<UserApiService>().getNotifications();
    });
  }

  Future<void> _act(Map<String, dynamic> notification) async {
    final id = (notification['id'] ?? notification['Id']).toString();
    final action = (notification['action'] ?? notification['Action'] ?? '')
        .toString();
    final resourceId =
        (notification['resourceId'] ?? notification['ResourceId'] ?? '')
            .toString();
    try {
      if (action.isNotEmpty) {
        await sl<UserApiService>().actOnNotification(id, action);
      }
      sl<SignalRService>().emitLocalChange('notification', {
        'resourceId': resourceId,
      });
      if (!mounted) return;
      VibeSnackBar.success(context, 'Updated successfully');
      widget.onChanged();
      await _refresh();
    } catch (e) {
      if (mounted) VibeFeedback.apiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final notifications = snapshot.data ?? [];
        if (notifications.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: VibeEmptyState(
                title: 'No notifications',
                message: 'Friend requests and event invites will appear here.',
                icon: Icons.notifications_none_rounded,
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final n = notifications[index];
              final action = (n['action'] ?? n['Action'] ?? '').toString();
              return AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF171D2A) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? Colors.white10 : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (n['title'] ?? n['Title'] ?? 'Notification')
                                .toString(),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (n['body'] ?? n['Body'] ?? '').toString(),
                            style: const TextStyle(
                              color: AppColors.textHint,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (action.isNotEmpty)
                      TextButton(
                        onPressed: () => _act(n),
                        child: const Text('Accept'),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
