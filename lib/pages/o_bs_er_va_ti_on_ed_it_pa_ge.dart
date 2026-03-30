import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class ObservationEditPage extends StatelessWidget {
  const ObservationEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ObservationEditPage')),
      body: const Center(child: Text('ObservationEditPage - TODO')),
    );
  }
}

