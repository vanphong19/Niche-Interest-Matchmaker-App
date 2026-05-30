// lib/features/home/presentation/pages/messages_page.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../chat/presentation/pages/chat_inbox_page.dart';

@RoutePage()
class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChatInboxPage();
  }
}
