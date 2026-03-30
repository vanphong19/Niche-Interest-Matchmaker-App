import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class ObservationPage extends StatelessWidget {
  const ObservationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ObservationPage')),
      body: const Center(child: Text('ObservationPage - TODO')),
    );
  }
}

