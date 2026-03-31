import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:niche_interest_matchmaker_app/features/base/bloc/base_bloc_event.dart';

part 'settings_event.freezed.dart';

@freezed
abstract class SettingsEvent extends BaseBlocEvent with _$SettingsEvent {
  const SettingsEvent._();

  const factory SettingsEvent.started() = _Started;
  const factory SettingsEvent.notificationsToggled(bool enabled) =
      _NotificationsToggled;
  const factory SettingsEvent.languageChanged(String languageCode) =
      _LanguageChanged;
}
