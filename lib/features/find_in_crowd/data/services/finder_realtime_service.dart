import 'dart:async';

import '../../../../core/services/signalr_service.dart';
import '../../domain/entities/finder_models.dart';

class FinderRealtimeEvent {
  const FinderRealtimeEvent({required this.name, required this.data});

  final String name;
  final Map<String, dynamic> data;

  bool get isFinderEvent {
    final normalized = name.toLowerCase();
    return normalized.startsWith('finder.') ||
        normalized.startsWith('onfinder');
  }
}

class FinderRealtimeService {
  FinderRealtimeService(this._signalRService);

  final SignalRService _signalRService;

  Stream<FinderRealtimeEvent> get events {
    return _signalRService.dataChangeStream
        .map((payload) {
          final eventName = (payload['_event'] ?? payload['event'] ?? '')
              .toString();
          return FinderRealtimeEvent(name: eventName, data: payload);
        })
        .where((event) => event.isFinderEvent);
  }

  Stream<FinderRequest> requestEvents() {
    return events
        .where((event) => event.name.toLowerCase().contains('request'))
        .map((event) => FinderRequest.fromJson(event.data));
  }

  Stream<FinderSession> sessionEvents() {
    return events
        .where((event) => event.name.toLowerCase().contains('session'))
        .map((event) => FinderSession.fromJson(event.data));
  }

  Stream<FinderLocation> locationEvents(String sessionId) {
    return events
        .where((event) => event.name.toLowerCase().contains('location'))
        .map((event) => FinderLocation.fromJson(event.data))
        .where((location) => location.sessionId == sessionId);
  }
}
