import 'package:flutter/material.dart';
import 'router/app_router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // Utilize the provider instance as specified by the user's config
    final appRouter = AppRouterProvider.instance;

    return MaterialApp.router(
      title: 'Niche Interest Matchmaker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter.config(),
    );
  }
}

