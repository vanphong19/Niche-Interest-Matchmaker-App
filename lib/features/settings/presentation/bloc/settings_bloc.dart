import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:niche_interest_matchmaker_app/features/base/bloc/base_bloc.dart';

import 'settings_event.dart';
import 'settings_state.dart';

@Injectable()
class SettingsBloc extends BaseBloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsState()) {
    on<SettingsEvent>(_onSettingsEvent);
  }

  Future<void> _onSettingsEvent(
    SettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    event.when(
      started: () {
        emit(const SettingsState());
      },
      notificationsToggled: (enabled) {
        emit(state.copyWith(notificationsEnabled: enabled));
      },
      languageChanged: (languageCode) {
        emit(state.copyWith(languageCode: languageCode));
      },
    );
  }
}
