import 'package:niche_interest_matchmaker_app/features/base/bloc/base_bloc_event.dart';

abstract class GroupVibeCheckEvent extends BaseBlocEvent {
  const GroupVibeCheckEvent();
}

class PerformGroupVibeCheck extends GroupVibeCheckEvent {
  const PerformGroupVibeCheck(this.matchId, {this.maxMembers});

  final String matchId;
  final int? maxMembers;
}

class ResetGroupVibeCheck extends GroupVibeCheckEvent {
  const ResetGroupVibeCheck();
}
