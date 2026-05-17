import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'other_user_profile_page.dart';

@RoutePage()
class PublicProfilePage extends StatelessWidget {
  const PublicProfilePage({super.key, @PathParam('id') required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return OtherUserProfilePage(userId: userId);
  }
}
