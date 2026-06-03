import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:niche_interest_matchmaker_app/features/base/bloc/base_bloc.dart';

import '../../domain/repositories/vibe_check_repository.dart';
import 'group_vibe_check_event.dart';
import 'group_vibe_check_state.dart';

@injectable
class GroupVibeCheckBloc
    extends BaseBloc<GroupVibeCheckEvent, GroupVibeCheckState> {
  GroupVibeCheckBloc(this._repository) : super(const GroupVibeCheckInitial()) {
    on<PerformGroupVibeCheck>(_onPerformGroupVibeCheck);
    on<ResetGroupVibeCheck>(_onResetGroupVibeCheck);
  }

  final VibeCheckRepository _repository;

  Future<void> _onPerformGroupVibeCheck(
    PerformGroupVibeCheck event,
    Emitter<GroupVibeCheckState> emit,
  ) async {
    emit(const GroupVibeCheckLoading());

    await runBlocCatching(
      action: () async {
        final result = await _repository.checkGroupVibe(
          event.matchId,
          maxMembers: event.maxMembers,
        );
        emit(GroupVibeCheckSuccess(result));
      },
      doOnError: (error, _) async {
        emit(GroupVibeCheckError(_friendlyMessage(error)));
      },
    );
  }

  void _onResetGroupVibeCheck(
    ResetGroupVibeCheck event,
    Emitter<GroupVibeCheckState> emit,
  ) {
    emit(const GroupVibeCheckInitial());
  }

  String _friendlyMessage(Object error) {
    final raw = error.toString();
    return raw
        .replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '')
        .replaceFirst(RegExp(r'\s*\(status:\s*\d+\)$'), '')
        .replaceFirst('Exception: ', '')
        .trim();
  }
}
