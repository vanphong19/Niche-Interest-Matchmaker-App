import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class InspectionSettingsPage extends StatelessWidget {
  const InspectionSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('InspectionSettingsPage')),
      body: const Center(child: Text('InspectionSettingsPage - TODO')),
    );
  }
}

