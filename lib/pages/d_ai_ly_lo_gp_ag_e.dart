import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class DailyLogPage extends StatelessWidget {
  const DailyLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DailyLogPage')),
      body: const Center(child: Text('DailyLogPage - TODO')),
    );
  }
}

