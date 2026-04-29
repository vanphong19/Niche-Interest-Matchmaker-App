import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';
import 'package:niche_interest_matchmaker_app/features/base/bloc/base_bloc_state.dart';

part 'vibe_match_state.freezed.dart';

enum VibeMatchUiAction { openJoinSummary, openUserMatchList }

@freezed
abstract class MatchReason with _$MatchReason {
  const factory MatchReason({
    required String label,
    required IconData icon,
    required bool highlighted,
  }) = _MatchReason;
}

@freezed
abstract class VibeMatchState extends BaseBlocState with _$VibeMatchState {
  const VibeMatchState._();

  const factory VibeMatchState({
    @Default(82) int matchScore,
    @Default('Great Alignment!') String headerTitle,
    @Default('You match well with this group\'s energy and interests.')
    String headerSubtitle,
    @Default(
      'A laid-back group looking for casual evening kickarounds followed '
      'by late-night coffee runs. High energy but very welcoming to newcomers.',
    )
    String groupSummary,
    @Default(8) int attendeesCount,
    @Default(<MatchReason>[]) List<MatchReason> reasons,
    @Default(<String>[]) List<String> participantImages,
    VibeMatchUiAction? uiAction,
  }) = _VibeMatchState;

  factory VibeMatchState.initial() => const VibeMatchState();
}
