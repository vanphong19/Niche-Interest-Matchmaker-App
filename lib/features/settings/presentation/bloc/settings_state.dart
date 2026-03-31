import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:niche_interest_matchmaker_app/features/base/bloc/base_bloc_state.dart';

part 'settings_state.freezed.dart';

@freezed
abstract class SettingsState extends BaseBlocState with _$SettingsState {
  const SettingsState._();

  const factory SettingsState({
    @Default(false) bool notificationsEnabled,
    @Default('vi') String languageCode,
  }) = _SettingsState;
}
