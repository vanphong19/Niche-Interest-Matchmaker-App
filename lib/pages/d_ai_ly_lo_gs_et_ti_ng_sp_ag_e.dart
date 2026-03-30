import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class DailyLogSettingsPage extends StatelessWidget {
  const DailyLogSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DailyLogSettingsPage')),
      body: const Center(child: Text('DailyLogSettingsPage - TODO')),
    );
  }
}

