import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class UploadFilePage extends StatelessWidget {
  const UploadFilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UploadFilePage')),
      body: const Center(child: Text('UploadFilePage - TODO')),
    );
  }
}

