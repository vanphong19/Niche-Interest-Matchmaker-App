import 'package:flutter/material.dart';

enum CheckinStatusTone { success, warning, error, neutral }

class CheckinParticipant {
  const CheckinParticipant({
    required this.name,
    required this.subtitle,
    required this.status,
    required this.tone,
    required this.imageUrl,
  });

  final String name;
  final String subtitle;
  final String status;
  final CheckinStatusTone tone;
  final String imageUrl;
}

class CheckinMethodOption {
  const CheckinMethodOption({
    required this.titleKey,
    required this.subtitleKey,
    required this.icon,
    this.recommended = false,
  });

  final String titleKey;
  final String subtitleKey;
  final IconData icon;
  final bool recommended;
}

class TrustActivityItem {
  const TrustActivityItem({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.points,
    required this.icon,
    required this.tone,
  });

  final String title;
  final String subtitle;
  final String status;
  final String points;
  final IconData icon;
  final CheckinStatusTone tone;
}

class TrustBadgeItem {
  const TrustBadgeItem({
    required this.label,
    required this.icon,
    required this.tone,
    this.locked = false,
  });

  final String label;
  final IconData icon;
  final CheckinStatusTone tone;
  final bool locked;
}
