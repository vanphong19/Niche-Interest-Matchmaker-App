import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../router/app_router.gr.dart';

@RoutePage()
class MainTabsPage extends StatelessWidget {
  const MainTabsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoTabsScaffold(
      routes: const [MapDiscoveryRoute(), CreateEventRoute(), SettingsRoute()],
      extendBody: true,
      backgroundColor: const Color(0xFFF4F6FF),
      bottomNavigationBuilder: (_, tabsRouter) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              _tabItem(
                index: 0,
                icon: Icons.explore_rounded,
                label: 'Discovery',
                tabsRouter: tabsRouter,
              ),
              _tabItem(
                index: 1,
                icon: Icons.add_circle_rounded,
                label: 'Create',
                tabsRouter: tabsRouter,
                highlighted: true,
              ),
              _tabItem(
                index: 2,
                icon: Icons.person_rounded,
                label: 'Profile',
                tabsRouter: tabsRouter,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tabItem({
    required int index,
    required IconData icon,
    required String label,
    required TabsRouter tabsRouter,
    bool highlighted = false,
  }) {
    final selected = tabsRouter.activeIndex == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => tabsRouter.setActiveIndex(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFEDF2FF)
                : highlighted
                ? const Color(0xFFF7FAFF)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: highlighted ? 24 : 20,
                color: selected
                    ? AppTheme.primaryColor
                    : const Color(0xFF8F98B2),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected
                      ? AppTheme.primaryColor
                      : const Color(0xFF8F98B2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
