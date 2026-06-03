import 'package:flutter/material.dart';

enum FinderParticipantStatus { available, waiting, sharing, nearby, ended }

class FinderParticipantUiModel {
  const FinderParticipantUiModel({
    required this.name,
    required this.fullName,
    required this.subtitle,
    required this.avatarUrl,
    required this.distanceLabel,
    required this.directionLabel,
    required this.statusLabel,
    required this.status,
    required this.accentColor,
  });

  final String name;
  final String fullName;
  final String subtitle;
  final String avatarUrl;
  final String distanceLabel;
  final String directionLabel;
  final String statusLabel;
  final FinderParticipantStatus status;
  final Color accentColor;
}

class FinderSessionUiModel {
  const FinderSessionUiModel({
    required this.title,
    required this.locationName,
    required this.locationAddress,
    required this.timeLabel,
    required this.meetingNote,
    required this.signalLabel,
    required this.accuracyLabel,
    required this.partner,
    required this.participants,
  });

  final String title;
  final String locationName;
  final String locationAddress;
  final String timeLabel;
  final String meetingNote;
  final String signalLabel;
  final String accuracyLabel;
  final FinderParticipantUiModel partner;
  final List<FinderParticipantUiModel> participants;
}
