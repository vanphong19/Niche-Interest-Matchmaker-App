import 'package:niche_interest_matchmaker_app/features/base/bloc/base_bloc_state.dart';
import '../../domain/entities/vibe_check_result.dart';

abstract class VibeCheckState extends BaseBlocState {
  const VibeCheckState();
}

class VibeCheckInitial extends VibeCheckState {
  const VibeCheckInitial();
}

class VibeCheckLoading extends VibeCheckState {
  const VibeCheckLoading();
}

class VibeCheckSuccess extends VibeCheckState {
  const VibeCheckSuccess(this.result);
  final VibeCheckResult result;
}

class VibeCheckError extends VibeCheckState {
  const VibeCheckError(this.message);
  final String message;
}
