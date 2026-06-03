import 'package:intl/intl.dart';

import '../../../../core/utils/app_localizations.dart';
import '../../../event/domain/entities/event.dart';

class CheckinEventDetails {
  const CheckinEventDetails({
    this.matchId,
    required this.title,
    required this.locationName,
    required this.locationAddress,
    required this.eventTime,
    this.imageUrl,
    this.startsAt,
    this.endsAt,
  });

  final String? matchId;
  final String title;
  final String locationName;
  final String locationAddress;
  final String eventTime;
  final String? imageUrl;
  final DateTime? startsAt;
  final DateTime? endsAt;

  bool get hasMatchContext => matchId != null && matchId!.trim().isNotEmpty;

  factory CheckinEventDetails.fromEvent(Event event) {
    final localStart = event.startDateTime.toLocal();
    final localEnd = event.endDateTime?.toLocal();
    final time = localEnd == null
        ? DateFormat('MMM d, HH:mm').format(localStart)
        : '${DateFormat('MMM d, HH:mm').format(localStart)} - '
              '${DateFormat('HH:mm').format(localEnd)}';

    return CheckinEventDetails(
      matchId: event.id,
      title: event.title,
      locationName: event.location.name,
      locationAddress: event.location.address,
      eventTime: time,
      imageUrl: event.photoUrls.isNotEmpty ? event.photoUrls.first : null,
      startsAt: event.startDateTime,
      endsAt: event.endDateTime,
    );
  }

  factory CheckinEventDetails.fallback({String? matchId}) {
    return CheckinEventDetails(
      matchId: matchId,
      title: AppLocalizations.tr('checkin_fallback_title'),
      locationName: AppLocalizations.tr('checkin_fallback_location_name'),
      locationAddress: AppLocalizations.tr('checkin_fallback_location_address'),
      eventTime: AppLocalizations.tr('checkin_fallback_time'),
    );
  }
}
