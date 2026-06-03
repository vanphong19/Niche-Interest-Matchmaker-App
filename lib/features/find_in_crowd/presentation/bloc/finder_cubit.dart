import 'dart:async';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

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
  StreamSubscription? _headingSubscription;
  StreamSubscription? _partnerLocationSubscription;
  StreamSubscription? _sessionLifecycleSubscription;
  StreamSubscription? _realtimeSubscription;
  DateTime? _lastSentAt;
  double? _lastKnownHeading;
  DateTime? _lastDeviceHeadingAt;
  FinderLocationUiModel? _lastHeadingLocation;
  bool _cancelRequestInFlight = false;

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
    if (isClosed ||
        _cancelRequestInFlight ||
        state.status != FinderFlowStatus.requestPending) {
      return;
    }

    _cancelRequestInFlight = true;
    emit(state.copyWith(status: FinderFlowStatus.stopping));
    try {
      await _repository.cancelRequest(requestId);
      if (!isClosed) {
        emit(state.copyWith(status: FinderFlowStatus.requestCancelled));
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: FinderFlowStatus.error,
            errorMessage: _friendlyError(e),
          ),
        );
      }
    } finally {
      _cancelRequestInFlight = false;
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
          clearEndReason: true,
          clearError: true,
        ),
      );
      _watchPartnerLocation(session.sessionId);
      _watchSessionLifecycle(session.sessionId);
      _startHeadingTracking();
      await _startLocationSharing(session.sessionId);
    } catch (e) {
      if (_isSessionGoneError(e)) {
        await _stopLocationSharing();
        emit(
          state.copyWith(
            status: FinderFlowStatus.ended,
            liveSharing: false,
            endReason: _sessionEndReasonFor(e),
            errorMessage: _friendlyError(e),
          ),
        );
        return;
      }
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
      emit(
        state.copyWith(
          status: FinderFlowStatus.ended,
          liveSharing: false,
          endReason: 'stopped',
        ),
      );
    } catch (e) {
      if (_isSessionGoneError(e)) {
        await _stopLocationSharing();
        emit(
          state.copyWith(
            status: FinderFlowStatus.ended,
            liveSharing: false,
            endReason: _sessionEndReasonFor(e),
          ),
        );
        return;
      }
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
      if (isClosed) return;
      _rememberHeading(location);
      final navigation = _navigationCalculator.calculate(
        current: location,
        target: state.partnerLocation,
        lastKnownHeading: _lastKnownHeading,
        usesDeviceCompass: _hasFreshDeviceHeading,
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
        await _sendLocationSafely(sessionId: sessionId, location: location);
      }
    });
  }

  Future<void> _sendLocationSafely({
    required String sessionId,
    required FinderLocationUiModel location,
  }) async {
    try {
      await _repository.sendLocation(sessionId: sessionId, location: location);
    } catch (error) {
      if (isClosed) return;

      final statusCode = error is DioException
          ? error.response?.statusCode
          : null;
      if (statusCode == 409 || statusCode == 403 || statusCode == 404) {
        await _stopLocationSharing();
        if (!isClosed) {
          emit(
            state.copyWith(
              status: FinderFlowStatus.ended,
              liveSharing: false,
              endReason: _sessionEndReasonFor(error),
              errorMessage: _friendlyError(error),
            ),
          );
        }
        return;
      }

      if (!isClosed) {
        emit(state.copyWith(status: FinderFlowStatus.reconnecting));
      }
    }
  }

  Future<void> _stopLocationSharing() async {
    await _locationSubscription?.cancel();
    await _headingSubscription?.cancel();
    await _partnerLocationSubscription?.cancel();
    await _sessionLifecycleSubscription?.cancel();
    _locationSubscription = null;
    _headingSubscription = null;
    _partnerLocationSubscription = null;
    _sessionLifecycleSubscription = null;
    _lastDeviceHeadingAt = null;
  }

  void _startHeadingTracking() {
    _headingSubscription?.cancel();
    _headingSubscription = _locationService.watchDeviceHeading().listen(
      (heading) {
        if (isClosed) return;
        _lastKnownHeading = heading;
        _lastDeviceHeadingAt = DateTime.now();
        final navigation = _navigationCalculator.calculate(
          current: state.currentLocation,
          target: state.partnerLocation,
          lastKnownHeading: _lastKnownHeading,
          usesDeviceCompass: true,
        );
        if (navigation == null) return;
        emit(
          state.copyWith(
            navigation: navigation,
            status: _statusForNavigation(navigation),
          ),
        );
      },
      onError: (_) {
        _lastDeviceHeadingAt = null;
      },
    );
  }

  void _watchPartnerLocation(String sessionId) {
    _partnerLocationSubscription?.cancel();
    _partnerLocationSubscription = _realtimeService
        .locationEvents(sessionId)
        .listen((event) {
          if (isClosed) return;
          final navigation = _navigationCalculator.calculate(
            current: state.currentLocation,
            target: event.location,
            lastKnownHeading: _lastKnownHeading,
            usesDeviceCompass: _hasFreshDeviceHeading,
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

  void _watchSessionLifecycle(String sessionId) {
    _sessionLifecycleSubscription?.cancel();
    _sessionLifecycleSubscription = _realtimeService.events.listen((
      event,
    ) async {
      if (isClosed) return;
      final name = event.name.toLowerCase();
      final isStopped =
          name.contains('session.stopped') ||
          name.contains('onfindersessionstopped');
      final isExpired =
          name.contains('session.expired') ||
          name.contains('onfindersessionexpired');
      if (!isStopped && !isExpired) return;

      final eventSessionId =
          (event.data['sessionId'] ?? event.data['SessionId'] ?? '').toString();
      if (eventSessionId.isNotEmpty && eventSessionId != sessionId) return;

      await _stopLocationSharing();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: FinderFlowStatus.ended,
          liveSharing: false,
          endReason: isExpired ? 'expired' : 'stopped',
          errorMessage: isExpired
              ? 'Finder session expired.'
              : 'Location sharing was stopped.',
        ),
      );
    });
  }

  void _watchRequest(String requestId) {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = _realtimeService.events.listen((event) async {
      if (isClosed) return;
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
        if (isClosed) return;
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
    if (_hasFreshDeviceHeading) return;

    if (location.headingDegrees != null) {
      _lastKnownHeading = location.headingDegrees;
      _lastHeadingLocation = location;
      return;
    }

    final previous = _lastHeadingLocation;
    if (previous == null) {
      _lastHeadingLocation = location;
      return;
    }

    final distance = Geolocator.distanceBetween(
      previous.latitude,
      previous.longitude,
      location.latitude,
      location.longitude,
    );
    if (distance >= 2.5 && location.accuracyMeters <= 35) {
      _lastKnownHeading =
          (Geolocator.bearingBetween(
                previous.latitude,
                previous.longitude,
                location.latitude,
                location.longitude,
              ) +
              360) %
          360;
      _lastHeadingLocation = location;
    }
  }

  bool get _hasFreshDeviceHeading {
    final lastDeviceHeadingAt = _lastDeviceHeadingAt;
    if (lastDeviceHeadingAt == null) return false;
    return DateTime.now().difference(lastDeviceHeadingAt) <=
        const Duration(seconds: 3);
  }

  bool _isSessionGoneError(Object error) {
    if (error is! DioException) return false;
    final statusCode = error.response?.statusCode;
    return statusCode == 409 || statusCode == 403 || statusCode == 404;
  }

  String _sessionEndReasonFor(Object error) {
    final code = _responseCode(error);
    if (code?.contains('EXPIRED') == true) return 'expired';
    return 'stopped';
  }

  String? _responseCode(Object error) {
    if (error is! DioException) return null;
    final data = error.response?.data;
    if (data is Map) {
      final nestedData = data['data'] ?? data['Data'];
      if (nestedData is Map) {
        return (nestedData['code'] ??
                nestedData['Code'] ??
                nestedData['message'] ??
                nestedData['Message'])
            ?.toString();
      }
      return (data['code'] ??
              data['Code'] ??
              data['message'] ??
              data['Message'])
          ?.toString();
    }
    return null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (this.state.session?.isActive != true) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _locationSubscription?.pause();
      _headingSubscription?.pause();
      emit(this.state.copyWith(status: FinderFlowStatus.reconnecting));
    } else if (state == AppLifecycleState.resumed) {
      _locationSubscription?.resume();
      _headingSubscription?.resume();
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
    if (error is DioException) {
      final responseMessage = _responseCode(error);
      if (error.response?.statusCode == 409) {
        if (responseMessage != null && responseMessage.isNotEmpty) {
          return responseMessage.replaceAll('_', ' ');
        }
        return 'This Finder session has ended or is no longer active.';
      }
      if (error.response?.statusCode == 403) {
        return 'You no longer have access to this Finder session.';
      }
      if (error.response?.statusCode == 404) {
        return 'This Finder session was not found.';
      }
    }

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
