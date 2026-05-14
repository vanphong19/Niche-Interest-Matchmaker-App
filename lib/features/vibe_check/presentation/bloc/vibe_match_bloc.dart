import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:niche_interest_matchmaker_app/features/base/bloc/base_bloc.dart';
import 'package:niche_interest_matchmaker_app/core/utils/app_localizations.dart';

import 'vibe_match_event.dart';
import 'vibe_match_state.dart';

@injectable
class VibeMatchBloc extends BaseBloc<VibeMatchEvent, VibeMatchState> {
  VibeMatchBloc() : super(VibeMatchState.initial()) {
    on<VibeMatchEvent>(_onVibeMatchEvent);
  }

  Future<void> _onVibeMatchEvent(
    VibeMatchEvent event,
    Emitter<VibeMatchState> emit,
  ) {
    event.when(
      started: () {
        emit(
          state.copyWith(
            headerTitle: AppLocalizations.tr('vibe_match_headline'),
            headerSubtitle: AppLocalizations.tr('vibe_match_subtitle'),
            groupSummary: AppLocalizations.tr('vibe_match_summary_body'),
            reasons: const [
              MatchReason(
                label: 'vibe_match_reason_football',
                icon: Icons.sports_soccer,
                highlighted: true,
              ),
              MatchReason(
                label: 'vibe_match_reason_night',
                icon: Icons.dark_mode,
                highlighted: true,
              ),
              MatchReason(
                label: 'vibe_match_reason_nearby',
                icon: Icons.location_on,
                highlighted: true,
              ),
              MatchReason(
                label: 'vibe_match_reason_coffee',
                icon: Icons.coffee,
                highlighted: false,
              ),
            ],
            participantImages: const [
              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
              'https://images.unsplash.com/photo-1544005313-94ddf0286df2',
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d',
            ],
            uiAction: null,
          ),
        );
      },
      primaryPressed: () {
        emit(state.copyWith(uiAction: VibeMatchUiAction.openJoinSummary));
      },
      secondaryPressed: () {
        emit(state.copyWith(uiAction: VibeMatchUiAction.openUserMatchList));
      },
      navigationHandled: () {
        emit(state.copyWith(uiAction: null));
      },
    );

    return Future<void>.value();
  }
}
