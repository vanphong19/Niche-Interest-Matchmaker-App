import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class InspectionPage extends StatelessWidget {
  const InspectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('InspectionPage')),
      body: const Center(child: Text('InspectionPage - TODO')),
    );
  }
}

