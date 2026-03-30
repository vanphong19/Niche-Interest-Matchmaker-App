import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class ProjectSettingPage extends StatelessWidget {
  const ProjectSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ProjectSettingPage')),
      body: const Center(child: Text('ProjectSettingPage - TODO')),
    );
  }
}

