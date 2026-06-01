import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../models/checkin_event_details.dart';
import '../screens/nfc_checkin_screen.dart';

@RoutePage()
class NfcCheckinWaitingPage extends StatelessWidget {
  const NfcCheckinWaitingPage({super.key, this.matchId, this.eventDetails});

  final String? matchId;
  final CheckinEventDetails? eventDetails;

  @override
  Widget build(BuildContext context) {
    return NfcCheckinScreen(
      matchId: eventDetails?.matchId ?? matchId,
      eventDetails: eventDetails,
    );
  }
}
