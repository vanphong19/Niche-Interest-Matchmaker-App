import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/finder_models.dart';
import 'finder_participant_ui_model.dart';

FinderParticipantUiModel participantToUi(
  FinderParticipant participant, {
  String distanceLabel = '--',
  String directionLabel = 'Waiting',
  FinderParticipantStatus status = FinderParticipantStatus.sharing,
}) {
  return FinderParticipantUiModel(
    name: participant.firstName,
    fullName: participant.fullName,
    subtitle: 'Live finder participant',
    avatarUrl: participant.avatarUrl ?? '',
    distanceLabel: distanceLabel,
    directionLabel: directionLabel,
    statusLabel: 'Sharing',
    status: status,
    accentColor: AppColors.success,
  );
}
