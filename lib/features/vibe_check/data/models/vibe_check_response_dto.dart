// Vibe check response DTO - parse API wrapper.
// Entity chỉ nhận data thuần, không parse wrapper.
import '../../domain/entities/vibe_check_result.dart';
import '../../domain/entities/vibe_score_breakdown.dart';

class VibeCheckResponseDTO {
  final bool success;
  final VibeCheckDataDTO? data;
  final String? error;
  final String? errorCode;
  final String? message;

  VibeCheckResponseDTO({
    required this.success,
    this.data,
    this.error,
    this.errorCode,
    this.message,
  });

  factory VibeCheckResponseDTO.fromJson(Map<String, dynamic> json) {
    return VibeCheckResponseDTO(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null
          ? VibeCheckDataDTO.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      error: json['error'] as String?,
      errorCode: json['errorCode'] as String?,
      message: json['message'] as String?,
    );
  }

  VibeCheckResult? toEntity() {
    if (!success || data == null) return null;
    return data!.toEntity();
  }
}

class VibeCheckDataDTO {
  final String targetUserId;
  final String targetUserName;
  final String targetUserAvatar;
  final double overallScore;
  final int compatibilityPercentage;
  final String vibeLevel;
  final VibeScoreBreakdownDTO breakdown;
  final List<String> commonInterests;
  final String summary;
  final List<String> strengths;
  final List<String> risks;
  final List<String> conversationStarters;
  final List<String> suggestedDateIdeas;
  final DateTime checkedAtUtc;

  VibeCheckDataDTO({
    required this.targetUserId,
    required this.targetUserName,
    required this.targetUserAvatar,
    required this.overallScore,
    required this.compatibilityPercentage,
    required this.vibeLevel,
    required this.breakdown,
    required this.commonInterests,
    required this.summary,
    required this.strengths,
    required this.risks,
    required this.conversationStarters,
    required this.suggestedDateIdeas,
    required this.checkedAtUtc,
  });

  factory VibeCheckDataDTO.fromJson(Map<String, dynamic> json) {
    return VibeCheckDataDTO(
      targetUserId: json['targetUserId'] as String? ?? '',
      targetUserName: json['targetUserName'] as String? ?? '',
      targetUserAvatar: json['targetUserAvatar'] as String? ?? '',
      overallScore: (json['overallScore'] as num?)?.toDouble() ?? 0.0,
      compatibilityPercentage: json['compatibilityPercentage'] as int? ?? 0,
      vibeLevel: json['vibeLevel'] as String? ?? 'Low',
      breakdown: json['breakdown'] != null
          ? VibeScoreBreakdownDTO.fromJson(json['breakdown'] as Map<String, dynamic>)
          : const VibeScoreBreakdownDTO.empty(),
      commonInterests: (json['commonInterests'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      summary: json['summary'] as String? ?? '',
      strengths: (json['strengths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      risks: (json['risks'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      conversationStarters: (json['conversationStarters'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      suggestedDateIdeas: (json['suggestedDateIdeas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      checkedAtUtc: json['checkedAtUtc'] != null
          ? DateTime.parse(json['checkedAtUtc'] as String)
          : DateTime.now(),
    );
  }

  VibeCheckResult toEntity() {
    return VibeCheckResult(
      targetUserId: targetUserId,
      targetUserName: targetUserName,
      targetUserAvatar: targetUserAvatar,
      overallScore: overallScore,
      compatibilityPercentage: compatibilityPercentage,
      vibeLevel: vibeLevel,
      breakdown: breakdown.toEntity(),
      commonInterests: commonInterests,
      summary: summary,
      strengths: strengths,
      risks: risks,
      conversationStarters: conversationStarters,
      suggestedDateIdeas: suggestedDateIdeas,
      checkedAt: checkedAtUtc,
    );
  }
}

class VibeScoreBreakdownDTO {
  final double interests;
  final double bio;
  final double lifestyle;
  final double eventPreference;
  final double availability;
  final double location;
  final double reputation;

  const VibeScoreBreakdownDTO({
    required this.interests,
    required this.bio,
    required this.lifestyle,
    required this.eventPreference,
    required this.availability,
    required this.location,
    required this.reputation,
  });

  factory VibeScoreBreakdownDTO.fromJson(Map<String, dynamic> json) {
    return VibeScoreBreakdownDTO(
      interests: (json['interests'] as num?)?.toDouble() ?? 0.0,
      bio: (json['bio'] as num?)?.toDouble() ?? 0.0,
      lifestyle: (json['lifestyle'] as num?)?.toDouble() ?? 0.0,
      eventPreference:
          (json['eventPreference'] as num?)?.toDouble() ?? 0.0,
      availability: (json['availability'] as num?)?.toDouble() ?? 0.0,
      location: (json['location'] as num?)?.toDouble() ?? 0.0,
      reputation: (json['reputation'] as num?)?.toDouble() ?? 0.0,
    );
  }

  const VibeScoreBreakdownDTO.empty()
      : interests = 0.0,
        bio = 0.0,
        lifestyle = 0.0,
        eventPreference = 0.0,
        availability = 0.0,
        location = 0.0,
        reputation = 0.0;

  VibeScoreBreakdown toEntity() {
    return VibeScoreBreakdown(
      interests: interests,
      bio: bio,
      lifestyle: lifestyle,
      eventPreference: eventPreference,
      availability: availability,
      location: location,
      reputation: reputation,
    );
  }
}
