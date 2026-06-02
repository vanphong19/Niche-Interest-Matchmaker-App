import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/finder_location_service.dart';
import '../../data/services/finder_realtime_service.dart';
import '../../domain/entities/finder_models.dart';
import '../../domain/repositories/find_in_crowd_repository.dart';
import '../models/finder_location_ui_model.dart';
import '../services/finder_navigation_calculator.dart';
import 'finder_state.dart';

class FinderCubit extends Cubit<FinderState> with WidgetsBindingObserver {
  FinderCubit({
    required FindInCrowdRepository repository,
    required FinderRealtimeService realtimeService,
    required FinderLocationService locationService,
    FinderNavigationCalculator navigationCalculator =
        const FinderNavigationCalculator(),
  }) : _repository = repository,
       _realtimeService = realtimeService,
       _locationService = locationService,
       _navigationCalculator = navigationCalculator,
       super(FinderState.initial()) {
    WidgetsBinding.instance.addObserver(this);
  }

  final FindInCrowdRepository _repository;
  final FinderRealtimeService _realtimeService;
  final FinderLocationService _locationService;
  final FinderNavigationCalculator _navigationCalculator;

  StreamSubscription? _locationSubscription;
  StreamSubscription? _partnerLocationSubscription;
  StreamSubscription? _realtimeSubscription;
  DateTime? _lastSentAt;
  double? _lastKnownHeading;

  Future<void> loadMembers(String eventId) async {
    emit(
      state.copyWith(
        status: FinderFlowStatus.loadingMembers,
        eventId: eventId,
        clearError: true,
      ),
    );
    try {
      final members = await _repository.getEventMembers(eventId);
      final activeSession = await _repository.getActiveSession(eventId);
      emit(
        state.copyWith(
          status: FinderFlowStatus.membersLoaded,
          members: members,
          session: activeSession,
          partner: activeSession?.partner,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FinderFlowStatus.error,
          errorMessage: _friendlyError(e),
        ),
      );
    }
  }

  Future<void> prepareStart({
    required String eventId,
    required String partnerId,
  }) async {
    emit(
      state.copyWith(
        status: FinderFlowStatus.idle,
        eventId: eventId,
        clearError: true,
      ),
    );
    try {
      var partner = state.partner;
      if (partner?.userId != partnerId) {
        final members = state.members.isEmpty
            ? await _repository.getEventMembers(eventId)
            : state.members;
        final member = members.where((m) => m.userId == partnerId).firstOrNull;
        partner = FinderParticipant(
          userId: partnerId,
          fullName: member?.fullName ?? 'Partner',
          avatarUrl: member?.avatarUrl,
        );
        emit(state.copyWith(members: members, partner: partner));
      }
      await refreshCurrentLocation();
    } catch (e) {
      emit(
        state.copyWith(
          status: FinderFlowStatus.error,
          errorMessage: _friendlyError(e),
        ),
      );
    }
  }

  Future<void> refreshCurrentLocation() async {
    final permission = await _locationService.ensurePermission();
    if (permission != FinderLocationPermissionResult.granted) {
      emit(
        state.copyWith(
          status: FinderFlowStatus.permissionRequired,
          errorMessage: _permissionMessage(permission),
        ),
      );
      return;
    }
    final location = await _locationService.currentLocation();
    if (location == null) return;
    _rememberHeading(location);
    emit(
      state.copyWith(
        currentLocation: location,
        weakGps: location.accuracyMeters > 30,
        clearError: true,
      ),
    );
  }

  Future<void> sendRequest({
    required String eventId,
    required String partnerId,
  }) async {
    emit(
      state.copyWith(
        status: FinderFlowStatus.requestCreating,
        clearError: true,
      ),
    );
    try {
      final location =
          state.currentLocation ?? await _locationService.currentLocation();
      if (location == null) {
        emit(
          state.copyWith(
            status: FinderFlowStatus.permissionRequired,
            errorMessage: 'Location permission is needed to use Finder.',
          ),
        );
        return;
      }
      if (location.accuracyMeters > 100) {
        emit(
          state.copyWith(
            status: FinderFlowStatus.permissionRequired,
            weakGps: true,
            errorMessage:
                'GPS accuracy is too weak. Move near an open area and try again.',
          ),
        );
        return;
      }
      final request = await _repository.createRequest(
        eventId: eventId,
        receiverId: partnerId,
        initialLocation: location,
      );
      emit(
        state.copyWith(
          status: FinderFlowStatus.requestPending,
          request: request,
          currentLocation: location,
        ),
      );
      _watchRequest(request.requestId);
    } catch (e) {
      emit(
        state.copyWith(
          status: FinderFlowStatus.error,
          errorMessage: _friendlyError(e),
        ),
      );
    }
  }

  Future<void> loadIncomingRequest(String requestId) async {
    emit(
      state.copyWith(
        status: FinderFlowStatus.incomingRequest,
        clearError: true,
      ),
    );
    try {
      final request = await _repository.getRequest(requestId);
      emit(
        state.copyWith(
          request: request,
          eventId: request.eventId,
          partner: request.requester,
        ),
      );
      _watchRequest(requestId);
    } catch (e) {
      emit(
        state.copyWith(
          status: FinderFlowStatus.error,
          errorMessage: _friendlyError(e),
        ),
      );
    }
  }

  Future<void> waitForRequest(String requestId) async {
    emit(
      state.copyWith(status: FinderFlowStatus.requestPending, clearError: true),
    );
    try {
      final request = await _repository.getRequest(requestId);
      emit(
        state.copyWith(
          request: request,
          eventId: request.eventId,
          partner: request.requester,
        ),
      );
      _watchRequest(requestId);
    } catch (_) {
      _watchRequest(requestId);
    }
  }

  Future<void> acceptRequest(String requestId) async {
    emit(state.copyWith(status: FinderFlowStatus.sessionStarting));
    try {
      final location = await _locationService.currentLocation();
      if (location == null) {
        emit(
          state.copyWith(
            status: FinderFlowStatus.permissionRequired,
            errorMessage: 'Location permission is needed to use Finder.',
          ),
        );
        return;
      }
      final session = await _repository.respondRequest(
        requestId: requestId,
        accept: true,
        initialLocation: location,
      );
      if (session != null) await startSession(session.sessionId, session);
    } catch (e) {
      emit(
        state.copyWith(
          status: FinderFlowStatus.error,
          errorMessage: _friendlyError(e),
        ),
      );
    }
  }

  Future<void> declineRequest(String requestId) async {
    try {
      await _repository.respondRequest(requestId: requestId, accept: false);
      emit(state.copyWith(status: FinderFlowStatus.requestDeclined));
    } catch (e) {
      emit(
        state.copyWith(
          status: FinderFlowStatus.error,
          errorMessage: _friendlyError(e),
        ),
      );
    }
  }

  Future<void> cancelRequest(String requestId) async {
    try {
      await _repository.cancelRequest(requestId);
      emit(state.copyWith(status: FinderFlowStatus.requestCancelled));
    } catch (e) {
      emit(
        state.copyWith(
          status: FinderFlowStatus.error,
          errorMessage: _friendlyError(e),
        ),
      );
    }
  }

  void markRequestExpiredLocally(String requestId) {
    if (state.request?.requestId != requestId ||
        state.status != FinderFlowStatus.requestPending) {
      return;
    }
    emit(state.copyWith(status: FinderFlowStatus.requestExpired));
  }

  Future<void> startSession(
    String sessionId, [
    FinderSession? initialSession,
  ]) async {
    try {
      final session = initialSession ?? await _repository.getSession(sessionId);
      emit(
        state.copyWith(
          status: FinderFlowStatus.active,
          session: session,
          eventId: session.eventId,
          partner: session.partner,
          liveSharing: true,
          clearError: true,
        ),
      );
      _watchPartnerLocation(session.sessionId);
      await _startLocationSharing(session.sessionId);
    } catch (e) {
      emit(
        state.copyWith(
          status: FinderFlowStatus.error,
          errorMessage: _friendlyError(e),
        ),
      );
    }
  }

  Future<void> stopSession() async {
    final sessionId = state.session?.sessionId;
    if (sessionId == null) return;
    emit(state.copyWith(status: FinderFlowStatus.stopping));
    try {
      await _repository.stopSession(sessionId);
      await _stopLocationSharing();
      emit(state.copyWith(status: FinderFlowStatus.ended, liveSharing: false));
    } catch (e) {
      emit(
        state.copyWith(
          status: FinderFlowStatus.error,
          errorMessage: _friendlyError(e),
        ),
      );
    }
  }

  Future<void> _startLocationSharing(String sessionId) async {
    await _locationSubscription?.cancel();
    _locationSubscription = _locationService.watchLocation().listen((
      location,
    ) async {
      _rememberHeading(location);
      final navigation = _navigationCalculator.calculate(
        current: location,
        target: state.partnerLocation,
        lastKnownHeading: _lastKnownHeading,
      );
      emit(
        state.copyWith(
          currentLocation: location,
          navigation: navigation,
          weakGps: location.accuracyMeters > 30,
          status: _statusForNavigation(navigation),
        ),
      );
      final now = DateTime.now();
      if (_lastSentAt == null ||
          now.difference(_lastSentAt!) >= const Duration(seconds: 2)) {
        _lastSentAt = now;
        await _repository.sendLocation(
          sessionId: sessionId,
          location: location,
        );
      }
    });
  }

  Future<void> _stopLocationSharing() async {
    await _locationSubscription?.cancel();
    await _partnerLocationSubscription?.cancel();
    _locationSubscription = null;
    _partnerLocationSubscription = null;
  }

  void _watchPartnerLocation(String sessionId) {
    _partnerLocationSubscription?.cancel();
    _partnerLocationSubscription = _realtimeService
        .locationEvents(sessionId)
        .listen((event) {
          final navigation = _navigationCalculator.calculate(
            current: state.currentLocation,
            target: event.location,
            lastKnownHeading: _lastKnownHeading,
          );
          emit(
            state.copyWith(
              partnerLocation: event.location,
              partnerLocationUpdatedAt: DateTime.now(),
              navigation: navigation,
              status: _statusForNavigation(navigation),
            ),
          );
        });
  }

  void _watchRequest(String requestId) {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = _realtimeService.events.listen((event) async {
      final name = event.name.toLowerCase();
      final eventRequestId =
          (event.data['requestId'] ?? event.data['RequestId'] ?? '').toString();
      if (eventRequestId.isNotEmpty && eventRequestId != requestId) return;
      if (name.contains('accepted')) {
        emit(state.copyWith(status: FinderFlowStatus.requestAccepted));
      } else if (name.contains('declined')) {
        emit(state.copyWith(status: FinderFlowStatus.requestDeclined));
      } else if (name.contains('cancelled') || name.contains('canceled')) {
        emit(state.copyWith(status: FinderFlowStatus.requestCancelled));
      } else if (name.contains('expired')) {
        emit(state.copyWith(status: FinderFlowStatus.requestExpired));
      }
      if (name.contains('session.started')) {
        final session = FinderSession.fromJson(event.data);
        await startSession(session.sessionId, session);
      }
    });
  }

  FinderFlowStatus _statusForNavigation(FinderNavigationUiModel? navigation) {
    if (navigation == null) return FinderFlowStatus.active;
    if (navigation.distanceMeters <= 5) return FinderFlowStatus.veryClose;
    if (navigation.distanceMeters <= 30) return FinderFlowStatus.nearby;
    return FinderFlowStatus.active;
  }

  void _rememberHeading(FinderLocationUiModel location) {
    if (location.headingDegrees != null) {
      _lastKnownHeading = location.headingDegrees;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (this.state.session?.isActive != true) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _locationSubscription?.pause();
      emit(this.state.copyWith(status: FinderFlowStatus.reconnecting));
    } else if (state == AppLifecycleState.resumed) {
      _locationSubscription?.resume();
      emit(this.state.copyWith(status: FinderFlowStatus.active));
    }
  }

  @override
  Future<void> close() async {
    WidgetsBinding.instance.removeObserver(this);
    await _stopLocationSharing();
    await _realtimeSubscription?.cancel();
    return super.close();
  }

  String _permissionMessage(FinderLocationPermissionResult result) {
    switch (result) {
      case FinderLocationPermissionResult.serviceOff:
        return 'GPS is off. Turn on GPS to use Finder.';
      case FinderLocationPermissionResult.deniedForever:
        return 'Enable location in app settings to use Finder.';
      case FinderLocationPermissionResult.denied:
        return 'Location permission is needed to use Finder.';
      case FinderLocationPermissionResult.granted:
        return '';
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('FINDER_MEMBER_NOT_ELIGIBLE')) {
      return 'This person is not available for Finder right now.';
    }
    if (message.contains('FINDER_REQUEST_EXPIRED')) {
      return 'This request has expired.';
    }
    if (message.contains('FINDER_SESSION_CONFLICT')) {
      return 'One of you is already in another Finder session.';
    }
    if (message.contains('FINDER_REQUEST_ALREADY_EXISTS')) {
      return 'You already have a pending Finder request.';
    }
    return message.replaceFirst('Exception: ', '');
  }
}
