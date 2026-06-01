import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../models/checkin_event_details.dart';
import '../screens/qr_checkin_screen.dart';

@RoutePage()
class QrCheckinScannerPage extends StatelessWidget {
  const QrCheckinScannerPage({super.key, this.matchId, this.eventDetails});

  final String? matchId;
  final CheckinEventDetails? eventDetails;

  @override
  Widget build(BuildContext context) {
    return QrCheckinScreen(
      matchId: eventDetails?.matchId ?? matchId,
      eventDetails: eventDetails,
    );
  }
}
