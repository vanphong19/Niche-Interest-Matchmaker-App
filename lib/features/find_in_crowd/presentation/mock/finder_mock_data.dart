import '../../../../core/theme/app_colors.dart';
import '../models/finder_participant_ui_model.dart';

class FinderMockData {
  FinderMockData._();

  static const currentUserAvatar =
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=300';

  static const sarah = FinderParticipantUiModel(
    name: 'Sarah',
    fullName: 'Sarah Jenkins',
    subtitle: 'Verified member - Coffee circle',
    avatarUrl:
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=300',
    distanceLabel: '12m',
    directionLabel: 'North-east',
    statusLabel: 'Nearby',
    status: FinderParticipantStatus.nearby,
    accentColor: AppColors.success,
  );

  static const phong = FinderParticipantUiModel(
    name: 'Phong',
    fullName: 'Phong Tran',
    subtitle: 'Wants to find you near the meeting point',
    avatarUrl:
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=300',
    distanceLabel: '18m',
    directionLabel: 'Main entrance',
    statusLabel: 'Requesting',
    status: FinderParticipantStatus.waiting,
    accentColor: AppColors.primary,
  );

  static const session = FinderSessionUiModel(
    title: 'Coffee with Sarah',
    locationName: 'The Commons Cafe',
    locationAddress: 'District 1, Ho Chi Minh City',
    timeLabel: 'Today, 6:30 PM',
    meetingNote: 'Sarah is near the event area',
    signalLabel: 'Strong signal',
    accuracyLabel: 'Approx. 3-12m',
    partner: sarah,
    participants: [
      sarah,
      FinderParticipantUiModel(
        name: 'Marcus',
        fullName: 'Marcus Tran',
        subtitle: 'Arrived near the south gate',
        avatarUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300',
        distanceLabel: '24m',
        directionLabel: 'South',
        statusLabel: 'Arrived',
        status: FinderParticipantStatus.available,
        accentColor: AppColors.accent,
      ),
      FinderParticipantUiModel(
        name: 'Jamie',
        fullName: 'Jamie Le',
        subtitle: 'Finding table seating',
        avatarUrl:
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=300',
        distanceLabel: '31m',
        directionLabel: 'Cafe bar',
        statusLabel: 'Available',
        status: FinderParticipantStatus.available,
        accentColor: AppColors.warning,
      ),
    ],
  );
}
