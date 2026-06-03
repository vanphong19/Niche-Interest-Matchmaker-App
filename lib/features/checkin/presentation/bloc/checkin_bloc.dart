import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
import 'package:niche_interest_matchmaker_app/core/services/signalr_service.dart';
import 'package:niche_interest_matchmaker_app/features/base/bloc/base_bloc.dart';
import 'package:niche_interest_matchmaker_app/injection/injection_container.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/utils/app_localizations.dart';
import '../../domain/entities/checkin_eligibility.dart';
import '../../domain/usecases/check_in_with_strategy_usecase.dart';
import '../../domain/usecases/get_checkin_eligibility_usecase.dart';
import 'checkin_event.dart';
import 'checkin_state.dart';

@Injectable()
class CheckinBloc extends BaseBloc<CheckinEvent, CheckinState> {
  CheckinBloc({
    CheckInWithStrategyUseCase? checkInWithStrategyUseCase,
    GetCheckinEligibilityUseCase? getEligibilityUseCase,
  }) : _checkInWithStrategyUseCase = checkInWithStrategyUseCase,
       _getEligibilityUseCase = getEligibilityUseCase,
       super(const CheckinState()) {
    on<CheckinEvent>(_onCheckinEvent);
  }

  final CheckInWithStrategyUseCase? _checkInWithStrategyUseCase;
  final GetCheckinEligibilityUseCase? _getEligibilityUseCase;
  bool _nfcSessionActive = false;

  Future<void> _onCheckinEvent(
    CheckinEvent event,
    Emitter<CheckinState> emit,
  ) async {
    switch (event) {
      case CheckinStarted():
        await _stopNfcSession();
        emit(const CheckinState());
      case QrCheckinRequested(:final matchId, :final startsAt, :final endsAt):
        emit(
          state.copyWith(
            matchId: matchId,
            startsAt: startsAt,
            endsAt: endsAt,
            clearErrorMessage: true,
            clearResult: true,
            clearEligibility: true,
          ),
        );
        await _startQrCheckin(emit);
      case QrRetryRequested():
        await _startQrCheckin(emit);
      case QrCodeDetected(:final value):
        await _handleQrDetected(value, emit);
      case NfcCheckinRequested(:final matchId, :final startsAt, :final endsAt):
        emit(
          state.copyWith(
            matchId: matchId,
            startsAt: startsAt,
            endsAt: endsAt,
            clearErrorMessage: true,
            clearResult: true,
            clearEligibility: true,
          ),
        );
        await _startNfcCheckin(emit);
      case NfcRetryRequested():
        await _startNfcCheckin(emit);
      case NfcTagDetected(:final value):
        await _handleNfcDetected(value, emit);
      case NfcScanStopped():
        await _stopNfcSession();
        emit(state.copyWith(nfcStatus: NfcCheckinStatus.initial));
    }
  }

  Future<void> _startQrCheckin(Emitter<CheckinState> emit) async {
    if (!_hasMatchContext) {
      emit(
        state.copyWith(
          qrStatus: QrCheckinStatus.failure,
          errorMessage: AppLocalizations.tr('checkin_missing_qr_context'),
        ),
      );
      return;
    }

    final allowed = await _ensureMethodAllowed(
      method: 'qr',
      emit: emit,
      qr: true,
    );
    if (!allowed) return;

    await _requestQrPermission(emit);
  }

  Future<void> _requestQrPermission(Emitter<CheckinState> emit) async {
    emit(
      state.copyWith(
        qrStatus: QrCheckinStatus.requestingPermission,
        clearErrorMessage: true,
      ),
    );

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      emit(
        state.copyWith(
          qrStatus: QrCheckinStatus.permissionDenied,
          errorMessage: AppLocalizations.tr('checkin_qr_permission_required'),
        ),
      );
      return;
    }

    final locationError = await _ensureLocationReady();
    if (locationError != null) {
      emit(
        state.copyWith(
          qrStatus: QrCheckinStatus.permissionDenied,
          errorMessage: locationError,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        qrStatus: QrCheckinStatus.scanning,
        clearErrorMessage: true,
      ),
    );
  }

  Future<bool> _ensureMethodAllowed({
    required String method,
    required Emitter<CheckinState> emit,
    required bool qr,
  }) async {
    if (_getEligibilityUseCase == null) {
      return true;
    }

    final matchId = state.matchId?.trim();
    if (matchId == null || matchId.isEmpty) {
      _emitMethodFailure(
        emit: emit,
        qr: qr,
        message:
            '${AppLocalizations.tr('checkin_missing_method_context_prefix')} '
            '${_methodLabel(method)} check-in.',
      );
      return false;
    }

    final result = await _getEligibilityUseCase(matchId);
    return result.fold(
      (failure) {
        _emitMethodFailure(emit: emit, qr: qr, message: failure.message);
        return false;
      },
      (eligibility) {
        emit(state.copyWith(eligibility: eligibility));
        final message = _eligibilityMessage(eligibility, method);
        if (message != null) {
          _emitMethodFailure(emit: emit, qr: qr, message: message);
          return false;
        }
        return true;
      },
    );
  }

  String? _eligibilityMessage(CheckinEligibility eligibility, String method) {
    if (eligibility.alreadyCheckedIn) {
      return AppLocalizations.tr('checkin_already_checked_in_meetup');
    }

    if (!eligibility.canCheckIn) {
      if (_canOverrideOutsideTimeWindow(eligibility.disabledReason)) {
        return null;
      }
      return _friendlyDisabledReason(
        eligibility.disabledReason ??
            AppLocalizations.tr('checkin_not_available_now'),
      );
    }

    final availability = eligibility.methodAvailability(method);
    if (availability == null) {
      return '${_methodLabel(method)} ${AppLocalizations.tr('checkin_method_not_available')}';
    }

    if (!availability.enabled) {
      if (_canOverrideOutsideTimeWindow(availability.disabledReason)) {
        return null;
      }
      return _friendlyDisabledReason(
        availability.disabledReason ??
            '${_methodLabel(method)} ${AppLocalizations.tr('checkin_method_disabled')}',
      );
    }

    return null;
  }

  bool _canOverrideOutsideTimeWindow(String? reason) {
    if (reason != 'outside_time_window') return false;

    final startsAt = state.startsAt;
    if (startsAt == null) return false;

    final now = DateTime.now();
    final endsAt = state.endsAt ?? startsAt.add(const Duration(hours: 1));
    return !now.isBefore(startsAt) && !now.isAfter(endsAt);
  }

  String _friendlyDisabledReason(String reason) {
    return switch (reason) {
      'not_participant' => AppLocalizations.tr('checkin_not_participant'),
      'participant_not_approved' => AppLocalizations.tr(
        'checkin_join_not_approved',
      ),
      'match_cancelled' => AppLocalizations.tr('checkin_match_cancelled'),
      'outside_time_window' => AppLocalizations.tr(
        'checkin_outside_time_window',
      ),
      'already_checked_in' => AppLocalizations.tr(
        'checkin_already_checked_in_meetup',
      ),
      'location_not_supported' => AppLocalizations.tr(
        'checkin_location_not_supported',
      ),
      'no_active_method' => AppLocalizations.tr('checkin_no_active_method'),
      'no_active_nfc_tag' => AppLocalizations.tr('checkin_no_active_nfc'),
      'no_active_qr_code' => AppLocalizations.tr('checkin_no_active_qr'),
      'location_missing_coordinates' => AppLocalizations.tr(
        'checkin_missing_gps_coordinates',
      ),
      'location_radius_missing' => AppLocalizations.tr(
        'checkin_missing_qr_radius',
      ),
      _ => reason.replaceAll('_', ' '),
    };
  }

  void _emitMethodFailure({
    required Emitter<CheckinState> emit,
    required bool qr,
    required String message,
  }) {
    emit(
      state.copyWith(
        qrStatus: qr ? QrCheckinStatus.failure : state.qrStatus,
        nfcStatus: qr ? state.nfcStatus : NfcCheckinStatus.failure,
        errorMessage: message,
      ),
    );
  }

  bool get _hasMatchContext {
    final matchId = state.matchId?.trim();
    return matchId != null && matchId.isNotEmpty;
  }

  Future<void> _handleQrDetected(
    String value,
    Emitter<CheckinState> emit,
  ) async {
    if (state.qrStatus == QrCheckinStatus.success || value.trim().isEmpty) {
      return;
    }

    if (state.matchId == null || state.matchId!.isEmpty) {
      emit(
        state.copyWith(
          qrStatus: QrCheckinStatus.failure,
          errorMessage: AppLocalizations.tr('checkin_missing_qr_context'),
        ),
      );
      return;
    }

    if (_checkInWithStrategyUseCase == null) {
      emit(
        state.copyWith(
          qrStatus: QrCheckinStatus.failure,
          errorMessage: AppLocalizations.tr('checkin_service_unavailable'),
        ),
      );
      return;
    }

    emit(state.copyWith(qrPayload: value, clearErrorMessage: true));

    final position = await _getFreshPosition();
    if (position == null) {
      emit(
        state.copyWith(
          qrStatus: QrCheckinStatus.failure,
          errorMessage: AppLocalizations.tr('checkin_unable_current_location'),
        ),
      );
      return;
    }

    final result = await _checkInWithStrategyUseCase(
      CheckInWithStrategyParams(
        method: 'qr',
        matchId: state.matchId!,
        payload: value,
        latitude: position.latitude,
        longitude: position.longitude,
        locationAccuracyMeters: position.accuracy,
        locationCapturedAtUtc: DateTime.now().toUtc(),
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          qrStatus: QrCheckinStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (checkin) {
        emit(
          state.copyWith(
            qrStatus: QrCheckinStatus.success,
            result: checkin,
            clearErrorMessage: true,
          ),
        );
        if (checkin.status == 'valid') {
          _notifyProfileChangedIfValid();
        }
      },
    );
  }

  Future<void> _startNfcCheckin(Emitter<CheckinState> emit) async {
    if (!_hasMatchContext) {
      emit(
        state.copyWith(
          nfcStatus: NfcCheckinStatus.failure,
          errorMessage: AppLocalizations.tr('checkin_missing_nfc_context'),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        nfcStatus: NfcCheckinStatus.checkingAvailability,
        clearErrorMessage: true,
      ),
    );

    final allowed = await _ensureMethodAllowed(
      method: 'nfc',
      emit: emit,
      qr: false,
    );
    if (!allowed) return;

    try {
      final availability = await NfcManager.instance.checkAvailability();

      switch (availability) {
        case NfcAvailability.enabled:
          emit(state.copyWith(nfcStatus: NfcCheckinStatus.readyToScan));
          await _stopNfcSession();
          await NfcManager.instance.startSession(
            pollingOptions: const {NfcPollingOption.iso14443},
            alertMessageIos: AppLocalizations.tr(
              'checkin_hold_device_near_nfc',
            ),
            onDiscovered: (tag) {
              _describeTag(
                tag,
              ).then((value) => add(CheckinEvent.nfcTagDetected(value)));
            },
          );
          _nfcSessionActive = true;
          emit(state.copyWith(nfcStatus: NfcCheckinStatus.scanning));
        case NfcAvailability.disabled:
          emit(
            state.copyWith(
              nfcStatus: NfcCheckinStatus.disabled,
              errorMessage: AppLocalizations.tr(
                'checkin_nfc_turned_off_try_again',
              ),
            ),
          );
        case NfcAvailability.unsupported:
          emit(
            state.copyWith(
              nfcStatus: NfcCheckinStatus.unsupported,
              errorMessage: AppLocalizations.tr('checkin_nfc_unsupported_desc'),
            ),
          );
      }
    } catch (_) {
      emit(
        state.copyWith(
          nfcStatus: NfcCheckinStatus.failure,
          errorMessage: AppLocalizations.tr(
            'checkin_unable_start_nfc_try_again',
          ),
        ),
      );
    }
  }

  Future<void> _handleNfcDetected(
    String value,
    Emitter<CheckinState> emit,
  ) async {
    await _stopNfcSession();

    emit(
      state.copyWith(
        nfcPayload: value,
        nfcStatus: NfcCheckinStatus.readyToScan,
        clearErrorMessage: true,
      ),
    );

    if (state.matchId == null || state.matchId!.isEmpty) {
      emit(
        state.copyWith(
          nfcStatus: NfcCheckinStatus.failure,
          errorMessage: AppLocalizations.tr('checkin_missing_nfc_context'),
        ),
      );
      return;
    }

    if (_checkInWithStrategyUseCase == null) {
      emit(
        state.copyWith(
          nfcStatus: NfcCheckinStatus.failure,
          errorMessage: AppLocalizations.tr('checkin_service_unavailable'),
        ),
      );
      return;
    }

    final result = await _checkInWithStrategyUseCase(
      CheckInWithStrategyParams(
        method: 'nfc',
        matchId: state.matchId!,
        payload: value,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          nfcStatus: NfcCheckinStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (checkin) {
        final status = checkin.status == 'valid'
            ? NfcCheckinStatus.success
            : checkin.status == 'duplicate'
            ? NfcCheckinStatus.duplicate
            : NfcCheckinStatus.rejected;
        emit(
          state.copyWith(
            nfcStatus: status,
            result: checkin,
            clearErrorMessage: true,
          ),
        );
        if (checkin.status == 'valid') {
          _notifyProfileChangedIfValid();
        }
      },
    );
  }

  void _notifyProfileChangedIfValid() {
    final result = state.result;
    if (result?.status != 'valid') return;
    sl<SignalRService>().emitLocalChange('profile', {
      'matchId': state.matchId,
      'reason': 'check-in',
    });
  }

  Future<String> _describeTag(NfcTag tag) async {
    final androidNdef = NdefAndroid.from(tag);
    final androidMessage =
        androidNdef?.cachedNdefMessage ?? await androidNdef?.getNdefMessage();
    final androidPayload = _readNdefPayload(androidMessage?.records);
    if (androidPayload != null) return androidPayload;

    final iosNdef = NdefIos.from(tag);
    final iosMessage = iosNdef?.cachedNdefMessage ?? await iosNdef?.readNdef();
    final iosPayload = _readNdefPayload(iosMessage?.records);
    if (iosPayload != null) return iosPayload;

    return tag.toString();
  }

  String? _readNdefPayload(List<dynamic>? records) {
    if (records == null || records.isEmpty) return null;
    for (final record in records) {
      final payload = record.payload;
      if (payload is! List<int> || payload.isEmpty) continue;
      final text = _decodeNdefPayload(payload);
      if (text != null && text.trim().isNotEmpty) return text.trim();
    }
    return null;
  }

  String? _decodeNdefPayload(List<int> payload) {
    try {
      final raw = utf8.decode(payload, allowMalformed: true);
      final uriIndex = raw.indexOf('vibepulse://');
      if (uriIndex >= 0) return raw.substring(uriIndex);
      final httpsIndex = raw.indexOf('https://');
      if (httpsIndex >= 0) return raw.substring(httpsIndex);
      final nfcIndex = raw.indexOf('NFC_');
      if (nfcIndex >= 0) return raw.substring(nfcIndex);
      if (payload.length > 3) {
        return utf8.decode(payload.skip(3).toList(), allowMalformed: true);
      }
      return raw;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _ensureLocationReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return AppLocalizations.tr('checkin_location_service_required');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return AppLocalizations.tr('checkin_location_permission_required');
    }

    return null;
  }

  Future<Position?> _getFreshPosition() async {
    try {
      final locationError = await _ensureLocationReady();
      if (locationError != null) return null;
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _stopNfcSession() async {
    if (!_nfcSessionActive) {
      return;
    }

    try {
      await NfcManager.instance.stopSession(
        alertMessageIos: AppLocalizations.tr('checkin_verified_ios_alert'),
      );
    } finally {
      _nfcSessionActive = false;
    }
  }

  @override
  Future<void> close() async {
    await _stopNfcSession();
    return super.close();
  }

  String _methodLabel(String method) {
    return switch (method.toLowerCase()) {
      'qr' => 'QR',
      'nfc' => 'NFC',
      _ => method.toUpperCase(),
    };
  }
}
