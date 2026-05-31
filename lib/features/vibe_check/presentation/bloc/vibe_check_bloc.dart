import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:niche_interest_matchmaker_app/features/base/bloc/base_bloc.dart';
import '../../domain/repositories/vibe_check_repository.dart';
import 'vibe_check_event.dart';
import 'vibe_check_state.dart';

@injectable
class VibeCheckBloc extends BaseBloc<VibeCheckEvent, VibeCheckState> {
  VibeCheckBloc(this._repository) : super(const VibeCheckInitial()) {
    on<PerformVibeCheck>(_onPerformVibeCheck);
    on<ResetVibeCheck>(_onResetVibeCheck);
  }

  final VibeCheckRepository _repository;

  Future<void> _onPerformVibeCheck(
    PerformVibeCheck event,
    Emitter<VibeCheckState> emit,
  ) async {
    emit(const VibeCheckLoading());

    await runBlocCatching(
      action: () async {
        final result = await _repository.checkVibe(event.targetUserId);
        emit(VibeCheckSuccess(result));
      },
      doOnError: (error, _) async {
        emit(VibeCheckError(error.toString()));
      },
    );
  }

  void _onResetVibeCheck(
    ResetVibeCheck event,
    Emitter<VibeCheckState> emit,
  ) {
    emit(const VibeCheckInitial());
  }
}
