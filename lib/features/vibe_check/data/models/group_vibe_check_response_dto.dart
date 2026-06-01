import '../../domain/entities/group_vibe_check_result.dart';

class GroupVibeCheckResponseDTO {
  const GroupVibeCheckResponseDTO({
    required this.success,
    this.data,
    this.error,
    this.errorCode,
    this.message,
  });

  final bool success;
  final GroupVibeCheckDataDTO? data;
  final String? error;
  final String? errorCode;
  final String? message;

  factory GroupVibeCheckResponseDTO.fromJson(Map<String, dynamic> json) {
    return GroupVibeCheckResponseDTO(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null
          ? GroupVibeCheckDataDTO.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      error: json['error'] as String?,
      errorCode: json['errorCode'] as String?,
      message: json['message'] as String?,
    );
  }

  GroupVibeCheckResult? toEntity() {
    if (!success || data == null) return null;
    return data!.toEntity();
  }
}

class GroupVibeCheckDataDTO {
  const GroupVibeCheckDataDTO({
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
    required this.checkedAtUtc,
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
  final GroupVibeBreakdownDTO breakdown;
  final List<GroupVibeMemberMatchDTO> topMatches;
  final List<String> groupStrengths;
  final List<String> watchouts;
  final List<String> conversationAngles;
  final List<String> suggestedActions;
  final String insightSource;
  final String? insightFallbackReason;
  final DateTime checkedAtUtc;

  factory GroupVibeCheckDataDTO.fromJson(Map<String, dynamic> json) {
    return GroupVibeCheckDataDTO(
      matchId: json['matchId'] as String? ?? '',
      matchName: json['matchName'] as String? ?? '',
      groupSize: json['groupSize'] as int? ?? 0,
      analyzedMemberCount: json['analyzedMemberCount'] as int? ?? 0,
      overallGroupScore: (json['overallGroupScore'] as num?)?.toDouble() ?? 0,
      compatibilityPercentage: json['compatibilityPercentage'] as int? ?? 0,
      vibeLevel: json['vibeLevel'] as String? ?? 'Low',
      groupVibeLabel: json['groupVibeLabel'] as String? ?? '',
      recommendation: json['recommendation'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      breakdown: json['breakdown'] != null
          ? GroupVibeBreakdownDTO.fromJson(
              json['breakdown'] as Map<String, dynamic>,
            )
          : const GroupVibeBreakdownDTO.empty(),
      topMatches: (json['topMatches'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(GroupVibeMemberMatchDTO.fromJson)
          .toList(),
      groupStrengths: _readStringList(json['groupStrengths']),
      watchouts: _readStringList(json['watchouts']),
      conversationAngles: _readStringList(json['conversationAngles']),
      suggestedActions: _readStringList(json['suggestedActions']),
      insightSource: json['insightSource'] as String? ?? 'fallback',
      insightFallbackReason: json['insightFallbackReason'] as String?,
      checkedAtUtc: json['checkedAtUtc'] != null
          ? DateTime.parse(json['checkedAtUtc'] as String)
          : DateTime.now(),
    );
  }

  GroupVibeCheckResult toEntity() {
    return GroupVibeCheckResult(
      matchId: matchId,
      matchName: matchName,
      groupSize: groupSize,
      analyzedMemberCount: analyzedMemberCount,
      overallGroupScore: overallGroupScore,
      compatibilityPercentage: compatibilityPercentage,
      vibeLevel: vibeLevel,
      groupVibeLabel: groupVibeLabel,
      recommendation: recommendation,
      summary: summary,
      breakdown: breakdown.toEntity(),
      topMatches: topMatches.map((item) => item.toEntity()).toList(),
      groupStrengths: groupStrengths,
      watchouts: watchouts,
      conversationAngles: conversationAngles,
      suggestedActions: suggestedActions,
      insightSource: insightSource,
      insightFallbackReason: insightFallbackReason,
      checkedAt: checkedAtUtc,
    );
  }

  static List<String> _readStringList(dynamic value) {
    return (value as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
  }
}

class GroupVibeBreakdownDTO {
  const GroupVibeBreakdownDTO({
    required this.memberCompatibility,
    required this.interestAlignment,
    required this.eventFit,
    required this.socialComfort,
    required this.locationFit,
    required this.groupReliability,
  });

  const GroupVibeBreakdownDTO.empty()
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

  factory GroupVibeBreakdownDTO.fromJson(Map<String, dynamic> json) {
    return GroupVibeBreakdownDTO(
      memberCompatibility:
          (json['memberCompatibility'] as num?)?.toDouble() ?? 0,
      interestAlignment: (json['interestAlignment'] as num?)?.toDouble() ?? 0,
      eventFit: (json['eventFit'] as num?)?.toDouble() ?? 0,
      socialComfort: (json['socialComfort'] as num?)?.toDouble() ?? 0,
      locationFit: (json['locationFit'] as num?)?.toDouble() ?? 0,
      groupReliability: (json['groupReliability'] as num?)?.toDouble() ?? 0,
    );
  }

  GroupVibeBreakdown toEntity() {
    return GroupVibeBreakdown(
      memberCompatibility: memberCompatibility,
      interestAlignment: interestAlignment,
      eventFit: eventFit,
      socialComfort: socialComfort,
      locationFit: locationFit,
      groupReliability: groupReliability,
    );
  }
}

class GroupVibeMemberMatchDTO {
  const GroupVibeMemberMatchDTO({
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

  factory GroupVibeMemberMatchDTO.fromJson(Map<String, dynamic> json) {
    return GroupVibeMemberMatchDTO(
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      score: (json['score'] as num?)?.toDouble() ?? 0,
      vibeLevel: json['vibeLevel'] as String? ?? 'Low',
      reason: json['reason'] as String? ?? '',
    );
  }

  GroupVibeMemberMatch toEntity() {
    return GroupVibeMemberMatch(
      userId: userId,
      name: name,
      avatarUrl: avatarUrl,
      score: score,
      vibeLevel: vibeLevel,
      reason: reason,
    );
  }
}
