import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../screens/nfc_checkin_screen.dart';

@RoutePage()
class NfcCheckinWaitingPage extends StatelessWidget {
  const NfcCheckinWaitingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const NfcCheckinScreen();
  }
}
