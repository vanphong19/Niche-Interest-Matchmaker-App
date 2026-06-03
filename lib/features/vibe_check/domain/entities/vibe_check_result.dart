import 'package:equatable/equatable.dart';

import 'vibe_score_breakdown.dart';

class VibeCheckResult extends Equatable {
  final String targetUserId;
  final String targetUserName;
  final String targetUserAvatar;
  final double overallScore;
  final int compatibilityPercentage;
  final String vibeLevel;
  final VibeScoreBreakdown breakdown;
  final List<String> commonInterests;
  final String summary;
  final String personalityTake;
  final String compatibilityConclusion;
  final String dateRecommendation;
  final String nextStep;
  final List<String> strengths;
  final List<String> risks;
  final List<String> conversationStarters;
  final List<String> suggestedDateIdeas;
  final DateTime checkedAt;

  const VibeCheckResult({
    required this.targetUserId,
    required this.targetUserName,
    required this.targetUserAvatar,
    required this.overallScore,
    required this.compatibilityPercentage,
    required this.vibeLevel,
    required this.breakdown,
    required this.commonInterests,
    required this.summary,
    required this.personalityTake,
    required this.compatibilityConclusion,
    required this.dateRecommendation,
    required this.nextStep,
    required this.strengths,
    required this.risks,
    required this.conversationStarters,
    required this.suggestedDateIdeas,
    required this.checkedAt,
  });

  @override
  List<Object?> get props => [
    targetUserId,
    overallScore,
    vibeLevel,
    compatibilityPercentage,
    personalityTake,
    compatibilityConclusion,
    dateRecommendation,
    nextStep,
  ];
}
