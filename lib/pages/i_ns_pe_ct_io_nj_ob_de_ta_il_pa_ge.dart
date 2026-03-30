import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class InspectionJobDetailPage extends StatelessWidget {
  const InspectionJobDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('InspectionJobDetailPage')),
      body: const Center(child: Text('InspectionJobDetailPage - TODO')),
    );
  }
}

