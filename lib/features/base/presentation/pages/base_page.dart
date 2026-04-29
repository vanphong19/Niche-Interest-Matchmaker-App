// lib/features/base/presentation/pages/base_page.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../router/app_router.gr.dart';
import '../widgets/vibe_bottom_nav.dart';

@RoutePage()
class BasePage extends StatefulWidget {
  const BasePage({super.key});

  @override
  State<BasePage> createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> {
  int _currentIndex = 0;

  /// Maps tab index to nested route index.
  /// Tab 2 (Create) is a special action, so index mapping skips it.
  int _mapTabToRouteIndex(int tabIndex) {
    if (tabIndex < 2) return tabIndex;
    // Tab 3 -> route index 2 (Activity)
    // Tab 4 -> route index 3 (Profile)
    return tabIndex - 1;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
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
        MapDiscoveryRoute(),
        ActivityRoute(),
        ProfileRoute(),
      ],
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);

        // Sync the current tab with the active route index
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final routeIndex = _mapTabToRouteIndex(_currentIndex);
          if (tabsRouter.activeIndex != routeIndex) {
            tabsRouter.setActiveIndex(routeIndex);
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
