import 'package:flutter/material.dart';

import 'checkin_top_bar.dart';

class CheckinScaffold extends StatelessWidget {
  const CheckinScaffold({
    super.key,
    required this.body,
    this.title = 'Check-in',
    this.leadingIcon,
    this.onLeadingPressed,
    this.trailingIcon,
    this.onTrailingPressed,
    this.activeTab = CheckinShellTab.meetups,
    this.showTopBar = true,
    this.showBottomNav = false,
    this.extendBody = false,
  });

  final Widget body;
  final String title;
  final IconData? leadingIcon;
  final VoidCallback? onLeadingPressed;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingPressed;
  final CheckinShellTab activeTab;
  final bool showTopBar;
  final bool showBottomNav;
  final bool extendBody;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      extendBody: extendBody,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (showTopBar)
              CheckinTopBar(
                title: title,
                leadingIcon: leadingIcon,
                onLeadingPressed: onLeadingPressed,
                trailingIcon: trailingIcon,
                onTrailingPressed: onTrailingPressed,
              ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

enum CheckinShellTab { explore, meetups, scan, trust }
