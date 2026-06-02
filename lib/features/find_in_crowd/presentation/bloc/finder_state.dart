import 'package:equatable/equatable.dart';

import '../../domain/entities/finder_models.dart';
import '../models/finder_location_ui_model.dart';

enum FinderFlowStatus {
  idle,
  loadingMembers,
  membersLoaded,
  permissionRequired,
  requestCreating,
  requestPending,
  requestAccepted,
  sessionStarting,
  requestDeclined,
  requestExpired,
  requestCancelled,
  incomingRequest,
  active,
  nearby,
  veryClose,
  reconnecting,
  stopping,
  ended,
  error,
}

class FinderState extends Equatable {
  const FinderState({
    required this.status,
    this.eventId,
    this.members = const [],
    this.partner,
    this.request,
    this.session,
    this.currentLocation,
    this.partnerLocation,
    this.navigation,
    this.partnerLocationUpdatedAt,
    this.errorMessage,
    this.liveSharing = false,
    this.weakGps = false,
  });

  factory FinderState.initial() {
    return const FinderState(status: FinderFlowStatus.idle);
  }

  final FinderFlowStatus status;
  final String? eventId;
  final List<EventFinderMember> members;
  final FinderParticipant? partner;
  final FinderRequest? request;
  final FinderSession? session;
  final FinderLocationUiModel? currentLocation;
  final FinderLocationUiModel? partnerLocation;
  final FinderNavigationUiModel? navigation;
  final DateTime? partnerLocationUpdatedAt;
  final String? errorMessage;
  final bool liveSharing;
  final bool weakGps;

  bool get isNearby => (navigation?.distanceMeters ?? double.infinity) <= 30;
  bool get isVeryClose => (navigation?.distanceMeters ?? double.infinity) <= 5;
  bool get hasAccurateCurrentLocation {
    final accuracy = currentLocation?.accuracyMeters;
    return accuracy != null && accuracy <= 25;
  }

  bool get hasFreshPartnerLocation {
    final updatedAt = partnerLocationUpdatedAt;
    if (updatedAt == null) return false;
    return DateTime.now().difference(updatedAt) <= const Duration(seconds: 10);
  }

  bool get canOpenArFinder =>
      isNearby && hasAccurateCurrentLocation && hasFreshPartnerLocation;

  bool get hasStalePartnerLocation {
    final updatedAt = partnerLocationUpdatedAt;
    if (updatedAt == null) return false;
    return DateTime.now().difference(updatedAt) > const Duration(seconds: 10);
  }

  String get arReadinessMessage {
    if (!isNearby) return 'Move closer to unlock AR-style guidance.';
    if (!hasAccurateCurrentLocation) {
      return 'Improving location accuracy before opening AR-style guidance.';
    }
    if (!hasFreshPartnerLocation) {
      return 'Waiting for the latest partner location before opening AR-style guidance.';
    }
    return 'GPS is ready for AR-style guidance.';
  }

  FinderState copyWith({
    FinderFlowStatus? status,
    String? eventId,
    List<EventFinderMember>? members,
    FinderParticipant? partner,
    FinderRequest? request,
    FinderSession? session,
    FinderLocationUiModel? currentLocation,
    FinderLocationUiModel? partnerLocation,
    FinderNavigationUiModel? navigation,
    DateTime? partnerLocationUpdatedAt,
    String? errorMessage,
    bool? liveSharing,
    bool? weakGps,
    bool clearError = false,
  }) {
    return FinderState(
      status: status ?? this.status,
      eventId: eventId ?? this.eventId,
      members: members ?? this.members,
      partner: partner ?? this.partner,
      request: request ?? this.request,
      session: session ?? this.session,
      currentLocation: currentLocation ?? this.currentLocation,
      partnerLocation: partnerLocation ?? this.partnerLocation,
      navigation: navigation ?? this.navigation,
      partnerLocationUpdatedAt:
          partnerLocationUpdatedAt ?? this.partnerLocationUpdatedAt,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      liveSharing: liveSharing ?? this.liveSharing,
      weakGps: weakGps ?? this.weakGps,
    );
  }

  @override
  List<Object?> get props => [
    status,
    eventId,
    members,
    partner,
    request,
    session,
    currentLocation,
    partnerLocation,
    navigation,
    partnerLocationUpdatedAt,
    errorMessage,
    liveSharing,
    weakGps,
  ];
}
