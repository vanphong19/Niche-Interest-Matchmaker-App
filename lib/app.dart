import 'package:flutter/material.dart';
import 'package:niche_interest_matchmaker_app/core/constants/constants.dart';
import 'package:niche_interest_matchmaker_app/core/theme/theme.dart';

import 'router/app_router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // Utilize the provider instance as specified by the user's config
    final appRouter = AppRouterProvider.instance;

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter.config(),
    );
  }
}
