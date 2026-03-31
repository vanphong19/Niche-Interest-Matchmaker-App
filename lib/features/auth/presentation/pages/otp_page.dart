import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:niche_interest_matchmaker_app/core/widgets/feature_placeholder_page.dart';

@RoutePage()
class OtpPage extends StatelessWidget {
  const OtpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'OTP',
      description: 'Authentication module scaffold: OTP verification screen.',
    );
  }
}
