// lib/features/base/presentation/pages/base_page.dart
import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../router/app_router.gr.dart';
import '../../../../injection/injection_container.dart';
import '../../../chat/data/models/chat_room_model.dart';
import '../../../chat/data/services/chat_api_service.dart';
import '../../../chat/data/services/signalr_chat_service.dart';
import '../../../../core/services/signalr_service.dart';
import '../../../event/presentation/bloc/event_bloc.dart';
import '../../../../core/utils/profile_state.dart';
import '../widgets/vibe_bottom_nav.dart';

@RoutePage()
class BasePage extends StatefulWidget {
  const BasePage({super.key});

  @override
  State<BasePage> createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> {
  int _currentIndex = 0;
  int _messageUnreadCount = 0;
  DateTime? _lastHomeRefresh;
  DateTime? _lastMessagesRefresh;
  DateTime? _lastProfileRefresh;
  StreamSubscription<ChatMessageModel>? _chatMessageSub;
  StreamSubscription<Map<String, dynamic>>? _dataChangeSub;

  static const _refreshStaleAfter = Duration(minutes: 2);

  @override
  void initState() {
    super.initState();
    _loadMessageUnread();
    _connectChatRealtime();
    _dataChangeSub = sl<SignalRService>().dataChangeStream.listen((event) {
      if (event['_type'] == 'chat') {
        _loadMessageUnread();
      }
    });
  }

  @override
  void dispose() {
    _chatMessageSub?.cancel();
    _dataChangeSub?.cancel();
    super.dispose();
  }

  bool _isStale(DateTime? timestamp) {
    return timestamp == null ||
        DateTime.now().difference(timestamp) > _refreshStaleAfter;
  }

  /// Maps tab index to nested route index.
  /// Tab 2 (Create) is a special action, so index mapping skips it.
  int _mapTabToRouteIndex(int tabIndex) {
    if (tabIndex < 2) return tabIndex;
    // Tab 3 -> route index 2 (Messages)
    // Tab 4 -> route index 3 (Profile)
    return tabIndex - 1;
  }

  int _mapRouteToTabIndex(int routeIndex) {
    if (routeIndex < 2) return routeIndex;
    return routeIndex + 1;
  }

  void _onTabTapped(int index) {
    final previousIndex = _currentIndex;
    setState(() {
      _currentIndex = index;
    });
    if (index == 0 && (previousIndex != 0 || _isStale(_lastHomeRefresh))) {
      final bloc = sl<EventBloc>();
      bloc.add(LoadEvents(category: bloc.state.selectedCategory));
      _lastHomeRefresh = DateTime.now();
    } else if (index == 3 &&
        (previousIndex != 3 || _isStale(_lastMessagesRefresh))) {
      _loadMessageUnread();
      _lastMessagesRefresh = DateTime.now();
    } else if (index == 4 &&
        (previousIndex != 4 || _isStale(_lastProfileRefresh))) {
      ProfileState.init();
      _lastProfileRefresh = DateTime.now();
    }
  }

  void _onCreateTapped() {
    context.router.push(const CreateEventRoute());
  }

  Future<void> _loadMessageUnread() async {
    try {
      final rooms = await sl<ChatApiService>().getMyRooms();
      if (!mounted) return;
      setState(() {
        _messageUnreadCount = rooms.fold(
          0,
          (sum, room) => sum + room.unreadCount,
        );
      });
    } catch (_) {}
  }

  Future<void> _connectChatRealtime() async {
    final chatSignalR = sl<SignalRChatService>();
    await chatSignalR.connect();
    await _chatMessageSub?.cancel();
    _chatMessageSub = chatSignalR.onMessageReceived.listen((message) {
      if (!mounted) return;
      final currentUserId = ProfileState.notifier.value.id;
      if (message.senderId.toLowerCase() == currentUserId.toLowerCase()) {
        return;
      }

      setState(() => _messageUnreadCount += 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      routes: const [
        HomeRoute(),
        MapDiscoveryRoute(),
        ChatInboxRoute(),
        ProfileRoute(),
      ],
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final activeTab = _mapRouteToTabIndex(tabsRouter.activeIndex);
          if (mounted && activeTab != _currentIndex) {
            setState(() => _currentIndex = activeTab);
          }
        });

        return Scaffold(
          body: child,
          bottomNavigationBar: VibeBottomNav(
            currentIndex: _currentIndex,
            onTap: (index) {
              _onTabTapped(index);
              tabsRouter.setActiveIndex(_mapTabToRouteIndex(index));
            },
            onCreateTap: _onCreateTapped,
            messageUnreadCount: _messageUnreadCount,
          ),
        );
      },
    );
  }
}
