import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class VinaCADWebViewPage extends StatelessWidget {
  const VinaCADWebViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VinaCADWebViewPage')),
      body: const Center(child: Text('VinaCADWebViewPage - TODO')),
    );
  }
}

