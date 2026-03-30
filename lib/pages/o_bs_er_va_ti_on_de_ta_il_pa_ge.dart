import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class ObservationDetailPage extends StatelessWidget {
  const ObservationDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ObservationDetailPage')),
      body: const Center(child: Text('ObservationDetailPage - TODO')),
    );
  }
}

