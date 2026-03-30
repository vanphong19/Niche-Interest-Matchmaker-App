import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class InspectionCategoryEditPage extends StatelessWidget {
  const InspectionCategoryEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('InspectionCategoryEditPage')),
      body: const Center(child: Text('InspectionCategoryEditPage - TODO')),
    );
  }
}

