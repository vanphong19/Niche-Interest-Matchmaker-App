import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../domain/entities/finder_models.dart';
import 'finder_participant_ui_model.dart';

FinderParticipantUiModel participantToUi(
  FinderParticipant participant, {
  String distanceLabel = '--',
  String? directionLabel,
  FinderParticipantStatus status = FinderParticipantStatus.sharing,
}) {
  return FinderParticipantUiModel(
    name: participant.firstName,
    fullName: participant.fullName,
    subtitle: AppLocalizations.tr('finder_live_participant'),
    avatarUrl: participant.avatarUrl ?? '',
    distanceLabel: distanceLabel,
    directionLabel:
        directionLabel ?? AppLocalizations.tr('finder_waiting_location'),
    statusLabel: AppLocalizations.tr('finder_sharing'),
    status: status,
    accentColor: AppColors.success,
  );
}
