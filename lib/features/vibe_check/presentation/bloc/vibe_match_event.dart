import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:niche_interest_matchmaker_app/features/base/bloc/base_bloc_event.dart';

part 'vibe_match_event.freezed.dart';

@freezed
abstract class VibeMatchEvent extends BaseBlocEvent with _$VibeMatchEvent {
  const VibeMatchEvent._();

  const factory VibeMatchEvent.started() = _Started;
  const factory VibeMatchEvent.primaryPressed() = _PrimaryPressed;
  const factory VibeMatchEvent.secondaryPressed() = _SecondaryPressed;
  const factory VibeMatchEvent.navigationHandled() = _NavigationHandled;
}
