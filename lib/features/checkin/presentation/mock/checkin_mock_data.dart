import 'package:flutter/material.dart';

import '../models/checkin_ui_model.dart';

class CheckinMockData {
  CheckinMockData._();

  static const userName = 'Alex Nguyen';
  static const userAvatar =
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=300';
  static const eventTitle = 'Rooftop Coffee & Strategy';
  static const eventImage =
      'https://images.unsplash.com/photo-1519671482749-fd09be7ccebf?w=1200';
  static const locationName = 'Cloud Nine Rooftop Bar';
  static const locationAddress = 'District 1, Ho Chi Minh City';
  static const eventTime = 'Today, 6:30 PM';

  static const participants = [
    CheckinParticipant(
      name: 'Sarah J.',
      subtitle: 'Verified Member',
      status: 'Arrived',
      tone: CheckinStatusTone.success,
      imageUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=300',
    ),
    CheckinParticipant(
      name: 'Marcus T.',
      subtitle: 'Top Contributor',
      status: 'Pending',
      tone: CheckinStatusTone.neutral,
      imageUrl:
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=300',
    ),
    CheckinParticipant(
      name: 'Jamie L.',
      subtitle: 'New Member',
      status: 'Late',
      tone: CheckinStatusTone.warning,
      imageUrl:
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=300',
    ),
  ];

  static const methodOptions = [
    CheckinMethodOption(
      titleKey: 'checkin_qr_method',
      subtitleKey: 'checkin_qr_method_desc',
      icon: Icons.qr_code_scanner_rounded,
      recommended: true,
    ),
    CheckinMethodOption(
      titleKey: 'checkin_nfc_method',
      subtitleKey: 'checkin_nfc_method_desc',
      icon: Icons.contactless_rounded,
    ),
  ];

  static const trustActivities = [
    TrustActivityItem(
      title: 'Sunday Hike',
      subtitle: 'Nov 12 - Thao Dien',
      status: 'Arrived',
      points: '+15 XP',
      icon: Icons.hiking_rounded,
      tone: CheckinStatusTone.success,
    ),
    TrustActivityItem(
      title: 'Board Games',
      subtitle: 'Nov 08 - District 1',
      status: 'Late Risk',
      points: '-5 XP',
      icon: Icons.casino_rounded,
      tone: CheckinStatusTone.warning,
    ),
    TrustActivityItem(
      title: 'Art Walk',
      subtitle: 'Oct 29 - District 3',
      status: 'No-show',
      points: '-50 XP',
      icon: Icons.palette_rounded,
      tone: CheckinStatusTone.error,
    ),
  ];

  static const badges = [
    TrustBadgeItem(
      label: 'Early Bird',
      icon: Icons.wb_twilight_rounded,
      tone: CheckinStatusTone.neutral,
    ),
    TrustBadgeItem(
      label: 'Reliable Host',
      icon: Icons.verified_rounded,
      tone: CheckinStatusTone.success,
    ),
    TrustBadgeItem(
      label: 'Explorer',
      icon: Icons.map_rounded,
      tone: CheckinStatusTone.warning,
    ),
    TrustBadgeItem(
      label: 'Top Guest',
      icon: Icons.lock_rounded,
      tone: CheckinStatusTone.neutral,
      locked: true,
    ),
  ];
}
