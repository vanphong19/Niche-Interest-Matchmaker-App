import 'package:equatable/equatable.dart';

class VibeScoreBreakdown extends Equatable {
  final double interests;
  final double bio;
  final double lifestyle;
  final double eventPreference;
  final double availability;
  final double location;
  final double reputation;

  const VibeScoreBreakdown({
    required this.interests,
    required this.bio,
    required this.lifestyle,
    required this.eventPreference,
    required this.availability,
    required this.location,
    required this.reputation,
  });

  @override
  List<Object?> get props => [
        interests,
        bio,
        lifestyle,
        eventPreference,
        availability,
        location,
        reputation,
      ];
}
