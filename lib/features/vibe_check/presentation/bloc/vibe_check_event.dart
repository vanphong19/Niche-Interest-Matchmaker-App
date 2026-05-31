import 'package:niche_interest_matchmaker_app/features/base/bloc/base_bloc_event.dart';

abstract class VibeCheckEvent extends BaseBlocEvent {
  const VibeCheckEvent();
}

class PerformVibeCheck extends VibeCheckEvent {
  const PerformVibeCheck(this.targetUserId);
  final String targetUserId;
}

class ResetVibeCheck extends VibeCheckEvent {
  const ResetVibeCheck();
}
