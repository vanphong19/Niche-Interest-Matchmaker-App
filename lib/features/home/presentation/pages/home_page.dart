import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/home_cubit.dart';
import '../bloc/home_state.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit()..loadModules(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Niche Interest Matchmaker')),
        body: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final module = state.modules[index];
                return ListTile(
                  leading: const Icon(Icons.layers_outlined),
                  title: Text(module),
                  subtitle: const Text('Clean Architecture + BLoC scaffold'),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: state.modules.length,
            );
          },
        ),
      ),
    );
  }
}
