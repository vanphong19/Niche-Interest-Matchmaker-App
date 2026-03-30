import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class CreateInspectionJobPage extends StatelessWidget {
  const CreateInspectionJobPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CreateInspectionJobPage')),
      body: const Center(child: Text('CreateInspectionJobPage - TODO')),
    );
  }
}

