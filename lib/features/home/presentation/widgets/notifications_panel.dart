import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/services/signalr_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/profile_state.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../core/widgets/snackbar_service.dart';
import '../../../../core/widgets/vibe_empty_state.dart';
import '../../../../injection/injection_container.dart';
import '../../../event/data/services/event_api_service.dart';
import '../../../event/domain/entities/event.dart';
import '../../../profile/data/services/user_api_service.dart';

class NotificationsPanel extends StatefulWidget {
  const NotificationsPanel({super.key, this.onChanged});

  final VoidCallback? onChanged;

  @override
  State<NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<NotificationsPanel> {
  late Future<List<_NotificationViewData>> _future;
  StreamSubscription<Map<String, dynamic>>? _subscription;
  final Set<String> _actingIds = {};

  @override
  void initState() {
    super.initState();
    _future = _load();
    _subscription = sl<SignalRService>().notificationStream.listen((_) {
      if (mounted) _refresh();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<List<_NotificationViewData>> _load() async {
    final rawItems = await sl<UserApiService>().getNotifications();
    return Future.wait(rawItems.map(_NotificationViewData.fromRaw));
  }

  Future<void> _refresh() async {
    final nextFuture = _load();
    setState(() {
      _future = nextFuture;
    });
    widget.onChanged?.call();
    await nextFuture;
  }

  Future<void> _accept(_NotificationViewData item) async {
    await _act(item, accept: true);
  }

  Future<void> _decline(_NotificationViewData item) async {
    await _act(item, accept: false);
  }

  Future<void> _act(_NotificationViewData item, {required bool accept}) async {
    setState(() {
      _actingIds.add(item.id);
    });

    try {
      final userApi = sl<UserApiService>();
      final eventApi = sl<EventApiService>();

      if (item.type == 'friend_request' && item.actorId.isNotEmpty) {
        if (accept) {
          await userApi.acceptFriend(item.actorId);
        } else {
          await userApi.rejectFriend(item.actorId);
        }
        await userApi.markNotificationRead(item.id);
      } else if (item.type == 'event_invite' && item.resourceId.isNotEmpty) {
        if (accept) {
          await userApi.actOnNotification(item.id, 'accept_event_invite');
        } else {
          await eventApi.leaveEvent(item.resourceId);
          await userApi.markNotificationRead(item.id);
        }
      } else if (item.type == 'join_request' &&
          item.resourceId.isNotEmpty &&
          item.actorId.isNotEmpty) {
        if (accept) {
          await eventApi.approveJoinRequest(item.resourceId, item.actorId);
        } else {
          await eventApi.rejectJoinRequest(item.resourceId, item.actorId);
        }
        await userApi.markNotificationRead(item.id);
      } else if (accept && item.action.isNotEmpty) {
        await userApi.actOnNotification(item.id, item.action);
      } else {
        await userApi.markNotificationRead(item.id);
      }

      sl<SignalRService>().emitLocalChange('notification', {
        'resourceId': item.resourceId,
      });
      if (!mounted) return;
      VibeSnackBar.success(context, accept ? 'Accepted' : 'Declined');
      await _refresh();
    } catch (e) {
      if (mounted) VibeFeedback.apiError(context, e);
    } finally {
      if (mounted) {
        setState(() {
          _actingIds.remove(item.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgPrimary : const Color(0xFFF5F7FF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFD5DDED),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<_NotificationViewData>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: VibeEmptyState(
                        title: 'No notifications',
                        message:
                            'Friend requests and event invites will appear here.',
                        icon: Icons.notifications_none_rounded,
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final canAct =
                            item.canAct && !_actingIds.contains(item.id);
                        return _NotificationCard(
                          item: item,
                          isDark: isDark,
                          canAct: canAct,
                          onAccept: canAct ? () => _accept(item) : null,
                          onDecline: canAct ? () => _decline(item) : null,
                          onMarkRead: !canAct && !item.isRead
                              ? () => _decline(item)
                              : null,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.isDark,
    required this.canAct,
    required this.onAccept,
    required this.onDecline,
    required this.onMarkRead,
  });

  final _NotificationViewData item;
  final bool isDark;
  final bool canAct;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onMarkRead;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171D2A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: item.isRead
              ? (isDark ? Colors.white10 : AppColors.borderLight)
              : AppColors.primary.withValues(alpha: 0.28),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: const Color(0xFF1C2C58).withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotificationThumb(item: item),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.secondary,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.eventName.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(
                            Icons.event_rounded,
                            color: AppColors.primary,
                            size: 15,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              item.eventName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (canAct)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(
                        color: isDark ? Colors.white12 : AppColors.borderLight,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Accept',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            )
          else if (onMarkRead != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onMarkRead,
                child: const Text('Mark as read'),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationThumb extends StatelessWidget {
  const _NotificationThumb({required this.item});

  final _NotificationViewData item;

  @override
  Widget build(BuildContext context) {
    if (item.kind == _NotificationKind.friend ||
        item.kind == _NotificationKind.joinRequest) {
      return VibeAvatar(
        imageUrl: item.avatarUrl,
        name: item.actorName.isNotEmpty ? item.actorName : item.title,
        size: 52,
        showBorder: false,
      );
    }

    if (item.imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          item.imageUrl,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _IconThumb(icon: item.icon),
        ),
      );
    }

    return _IconThumb(icon: item.icon);
  }
}

class _IconThumb extends StatelessWidget {
  const _IconThumb({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: AppColors.primary, size: 26),
    );
  }
}

enum _NotificationKind { friend, eventInvite, joinRequest, general }

class _NotificationViewData {
  const _NotificationViewData({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.actorId,
    required this.resourceId,
    required this.action,
    required this.isRead,
    required this.kind,
    this.actorName = '',
    this.avatarUrl = '',
    this.eventName = '',
    this.imageUrl = '',
  });

  final String id;
  final String type;
  final String title;
  final String subtitle;
  final String actorId;
  final String resourceId;
  final String action;
  final bool isRead;
  final _NotificationKind kind;
  final String actorName;
  final String avatarUrl;
  final String eventName;
  final String imageUrl;

  bool get canAct =>
      !isRead &&
      (type == 'friend_request' ||
          type == 'event_invite' ||
          type == 'join_request' ||
          action.isNotEmpty);

  IconData get icon {
    return switch (kind) {
      _NotificationKind.friend => Icons.person_add_alt_1_rounded,
      _NotificationKind.eventInvite => Icons.event_available_rounded,
      _NotificationKind.joinRequest => Icons.how_to_reg_rounded,
      _NotificationKind.general => Icons.notifications_rounded,
    };
  }

  static Future<_NotificationViewData> fromRaw(Map<String, dynamic> raw) async {
    final id = _read(raw, ['id', 'Id']);
    final type = _read(raw, ['type', 'Type']).toLowerCase();
    final body = _read(raw, ['body', 'Body']);
    final actorId = _read(raw, ['actorId', 'ActorId']);
    final resourceId = _read(raw, ['resourceId', 'ResourceId']);
    final action = _read(raw, ['action', 'Action']);
    final isRead = _readBool(raw, ['isRead', 'IsRead']);

    if (type == 'friend_request') {
      final profile = actorId.isNotEmpty ? await _safeProfile(actorId) : null;
      final name = profile?.name ?? 'Someone';
      return _NotificationViewData(
        id: id,
        type: type,
        title: '$name sent you a friend request',
        subtitle: body.isNotEmpty ? body : 'Add them to your circle.',
        actorId: actorId,
        resourceId: resourceId,
        action: action,
        isRead: isRead,
        kind: _NotificationKind.friend,
        actorName: name,
        avatarUrl: profile?.avatarUrl ?? '',
      );
    }

    if (type == 'event_invite') {
      final event = resourceId.isNotEmpty ? await _safeEvent(resourceId) : null;
      return _NotificationViewData(
        id: id,
        type: type,
        title: 'Event invite',
        subtitle: body.isNotEmpty
            ? body
            : 'You were invited to join this event.',
        actorId: actorId,
        resourceId: resourceId,
        action: action,
        isRead: isRead,
        kind: _NotificationKind.eventInvite,
        eventName: event?.title ?? _read(raw, ['title', 'Title']),
        imageUrl: event?.photoUrls.isNotEmpty == true
            ? event!.photoUrls.first
            : '',
      );
    }

    if (type == 'join_request') {
      final profile = actorId.isNotEmpty ? await _safeProfile(actorId) : null;
      final event = resourceId.isNotEmpty ? await _safeEvent(resourceId) : null;
      final name = profile?.name ?? 'Someone';
      return _NotificationViewData(
        id: id,
        type: type,
        title: '$name wants to join',
        subtitle: body.isNotEmpty ? body : 'Review this join request.',
        actorId: actorId,
        resourceId: resourceId,
        action: action,
        isRead: isRead,
        kind: _NotificationKind.joinRequest,
        actorName: name,
        avatarUrl: profile?.avatarUrl ?? '',
        eventName: event?.title ?? '',
        imageUrl: event?.photoUrls.isNotEmpty == true
            ? event!.photoUrls.first
            : '',
      );
    }

    return _NotificationViewData(
      id: id,
      type: type,
      title: _read(raw, ['title', 'Title']).isNotEmpty
          ? _read(raw, ['title', 'Title'])
          : 'Notification',
      subtitle: body,
      actorId: actorId,
      resourceId: resourceId,
      action: action,
      isRead: isRead,
      kind: _NotificationKind.general,
    );
  }

  static Future<ProfileData?> _safeProfile(String id) async {
    try {
      return await sl<UserApiService>().getOtherProfile(id);
    } catch (_) {
      return null;
    }
  }

  static Future<Event?> _safeEvent(String id) async {
    try {
      return await sl<EventApiService>().getEventDetail(id);
    } catch (_) {
      return null;
    }
  }

  static String _read(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  static bool _readBool(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is bool) return value;
      if (value != null) return value.toString().toLowerCase() == 'true';
    }
    return false;
  }
}
