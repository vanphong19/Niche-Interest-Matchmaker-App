import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../screens/qr_checkin_screen.dart';

@RoutePage()
class QrCheckinScannerPage extends StatelessWidget {
  const QrCheckinScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const QrCheckinScreen();
  }
}
