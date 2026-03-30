import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class ObservationSettingsPage extends StatelessWidget {
  const ObservationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ObservationSettingsPage')),
      body: const Center(child: Text('ObservationSettingsPage - TODO')),
    );
  }
}

