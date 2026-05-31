import 'package:equatable/equatable.dart';

class GroupVibeCheckResult extends Equatable {
  const GroupVibeCheckResult({
    required this.matchId,
    required this.matchName,
    required this.groupSize,
    required this.analyzedMemberCount,
    required this.overallGroupScore,
    required this.compatibilityPercentage,
    required this.vibeLevel,
    required this.groupVibeLabel,
    required this.recommendation,
    required this.summary,
    required this.breakdown,
    required this.topMatches,
    required this.groupStrengths,
    required this.watchouts,
    required this.conversationAngles,
    required this.suggestedActions,
    required this.insightSource,
    this.insightFallbackReason,
    required this.checkedAt,
  });

  final String matchId;
  final String matchName;
  final int groupSize;
  final int analyzedMemberCount;
  final double overallGroupScore;
  final int compatibilityPercentage;
  final String vibeLevel;
  final String groupVibeLabel;
  final String recommendation;
  final String summary;
  final GroupVibeBreakdown breakdown;
  final List<GroupVibeMemberMatch> topMatches;
  final List<String> groupStrengths;
  final List<String> watchouts;
  final List<String> conversationAngles;
  final List<String> suggestedActions;
  final String insightSource;
  final String? insightFallbackReason;
  final DateTime checkedAt;

  @override
  List<Object?> get props => [
    matchId,
    groupSize,
    analyzedMemberCount,
    overallGroupScore,
    compatibilityPercentage,
    vibeLevel,
    insightSource,
    insightFallbackReason,
  ];
}

class GroupVibeBreakdown extends Equatable {
  const GroupVibeBreakdown({
    required this.memberCompatibility,
    required this.interestAlignment,
    required this.eventFit,
    required this.socialComfort,
    required this.locationFit,
    required this.groupReliability,
  });

  const GroupVibeBreakdown.empty()
    : memberCompatibility = 0,
      interestAlignment = 0,
      eventFit = 0,
      socialComfort = 0,
      locationFit = 0,
      groupReliability = 0;

  final double memberCompatibility;
  final double interestAlignment;
  final double eventFit;
  final double socialComfort;
  final double locationFit;
  final double groupReliability;

  @override
  List<Object?> get props => [
    memberCompatibility,
    interestAlignment,
    eventFit,
    socialComfort,
    locationFit,
    groupReliability,
  ];
}

class GroupVibeMemberMatch extends Equatable {
  const GroupVibeMemberMatch({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.score,
    required this.vibeLevel,
    required this.reason,
  });

  final String userId;
  final String name;
  final String? avatarUrl;
  final double score;
  final String vibeLevel;
  final String reason;

  @override
  List<Object?> get props => [userId, score, vibeLevel, reason];
}
