import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../router/app_router.gr.dart';
import '../widgets/finder_action_button.dart';
import '../widgets/finder_glass_panel.dart';
import '../widgets/finder_map_background.dart';
import '../widgets/finder_scaffold.dart';

@RoutePage()
class FindInCrowdMeetingPage extends StatelessWidget {
  const FindInCrowdMeetingPage({super.key, this.eventId});

  final String? eventId;

  @override
  Widget build(BuildContext context) {
    return FinderScaffold(
      title: AppLocalizations.tr('finder_title'),
      subtitle: AppLocalizations.tr('finder_open_from_event'),
      background: const FinderMapBackground(),
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: FinderGlassPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.groups_rounded, size: 56),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  eventId == null
                      ? AppLocalizations.tr('finder_choose_member_first')
                      : AppLocalizations.tr('finder_continue_event_members'),
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppLocalizations.tr('finder_consent_flow_desc'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                FinderActionButton(
                  label: eventId == null
                      ? AppLocalizations.tr('finder_back_to_events')
                      : AppLocalizations.tr('finder_view_members'),
                  icon: Icons.group_rounded,
                  onPressed: () {
                    final id = eventId;
                    if (id == null || id.isEmpty) {
                      context.router.maybePop();
                    } else {
                      context.router.replace(ManageEventRoute(eventId: id));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
