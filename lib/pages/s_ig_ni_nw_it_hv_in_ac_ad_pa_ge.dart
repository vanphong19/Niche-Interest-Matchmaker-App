import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class SignInWithVinaCadPage extends StatelessWidget {
  const SignInWithVinaCadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SignInWithVinaCadPage')),
      body: const Center(child: Text('SignInWithVinaCadPage - TODO')),
    );
  }
}

