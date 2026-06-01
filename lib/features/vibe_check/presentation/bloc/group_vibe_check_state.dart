import 'package:niche_interest_matchmaker_app/features/base/bloc/base_bloc_state.dart';

import '../../domain/entities/group_vibe_check_result.dart';

abstract class GroupVibeCheckState extends BaseBlocState {
  const GroupVibeCheckState();
}

class GroupVibeCheckInitial extends GroupVibeCheckState {
  const GroupVibeCheckInitial();
}

class GroupVibeCheckLoading extends GroupVibeCheckState {
  const GroupVibeCheckLoading();
}

class GroupVibeCheckSuccess extends GroupVibeCheckState {
  const GroupVibeCheckSuccess(this.result);

  final GroupVibeCheckResult result;
}

class GroupVibeCheckError extends GroupVibeCheckState {
  const GroupVibeCheckError(this.message);

  final String message;
}
