import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class DailyLogTemplateEditPage extends StatelessWidget {
  const DailyLogTemplateEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DailyLogTemplateEditPage')),
      body: const Center(child: Text('DailyLogTemplateEditPage - TODO')),
    );
  }
}

