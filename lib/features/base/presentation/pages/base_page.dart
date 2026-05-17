// lib/features/base/presentation/pages/base_page.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../router/app_router.gr.dart';
import '../../../../injection/injection_container.dart';
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
  DateTime? _lastHomeRefresh;
  DateTime? _lastActivityRefresh;
  DateTime? _lastProfileRefresh;

  static const _refreshStaleAfter = Duration(minutes: 2);

  bool _isStale(DateTime? timestamp) {
    return timestamp == null ||
        DateTime.now().difference(timestamp) > _refreshStaleAfter;
  }

  /// Maps tab index to nested route index.
  /// Tab 2 (Create) is a special action, so index mapping skips it.
  int _mapTabToRouteIndex(int tabIndex) {
    if (tabIndex < 2) return tabIndex;
    // Tab 3 -> route index 2 (Activity)
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
        (previousIndex != 3 || _isStale(_lastActivityRefresh))) {
      sl<EventBloc>().add(LoadMyEvents());
      _lastActivityRefresh = DateTime.now();
    } else if (index == 4 &&
        (previousIndex != 4 || _isStale(_lastProfileRefresh))) {
      ProfileState.init();
      _lastProfileRefresh = DateTime.now();
    }
  }

  void _onCreateTapped() {
    context.router.push(const CreateEventRoute());
  }

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      routes: const [
        HomeRoute(),
        VibeMatchRoute(),
        ActivityRoute(),
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
            notificationCount: 3,
          ),
        );
      },
    );
  }
}
