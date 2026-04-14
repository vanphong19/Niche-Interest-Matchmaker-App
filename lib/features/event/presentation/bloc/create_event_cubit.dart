// lib/features/event/presentation/bloc/create_event_cubit.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:latlong2/latlong.dart';

import '../../data/services/event_api_service.dart';

class CreateEventState {
  final int currentStep;
  final String title;
  final String category;
  final List<String> vibeTags;
  final DateTime? date;
  final TimeOfDay? time;
  final int participants;
  final bool isEliteOnly;
  final bool isPublic;
  final String locationName;
  final String address;
  final LatLng? coordinates;
  final bool isSubmitting;
  final bool isSuccess;
  final String? error;

  const CreateEventState({
    this.currentStep = 0,
    this.title = '',
    this.category = 'Sports',
    this.vibeTags = const [],
    this.date,
    this.time,
    this.participants = 12,
    this.isEliteOnly = false,
    this.isPublic = true,
    this.locationName = '',
    this.address = '',
    this.coordinates,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.error,
  });

  CreateEventState copyWith({
    int? currentStep,
    String? title,
    String? category,
    List<String>? vibeTags,
    DateTime? date,
    TimeOfDay? time,
    int? participants,
    bool? isEliteOnly,
    bool? isPublic,
    String? locationName,
    String? address,
    LatLng? coordinates,
    bool? isSubmitting,
    bool? isSuccess,
    String? error,
  }) {
    return CreateEventState(
      currentStep: currentStep ?? this.currentStep,
      title: title ?? this.title,
      category: category ?? this.category,
      vibeTags: vibeTags ?? this.vibeTags,
      date: date ?? this.date,
      time: time ?? this.time,
      participants: participants ?? this.participants,
      isEliteOnly: isEliteOnly ?? this.isEliteOnly,
      isPublic: isPublic ?? this.isPublic,
      locationName: locationName ?? this.locationName,
      address: address ?? this.address,
      coordinates: coordinates ?? this.coordinates,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
    );
  }
}

@injectable
class CreateEventCubit extends Cubit<CreateEventState> {
  final EventApiService _apiService;

  CreateEventCubit(this._apiService) : super(const CreateEventState());

  void nextStep() {
    if (state.currentStep < 3) {
      emit(state.copyWith(currentStep: state.currentStep + 1));
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      emit(state.copyWith(currentStep: state.currentStep - 1));
    }
  }

  void goToStep(int step) {
    emit(state.copyWith(currentStep: step));
  }

  void updateVibe(String title, String category, List<String> tags) {
    emit(state.copyWith(title: title, category: category, vibeTags: tags));
  }

  void updateSchedule(
    DateTime date,
    TimeOfDay time,
    int participants,
    bool isElite,
    bool isPub,
  ) {
    emit(
      state.copyWith(
        date: date,
        time: time,
        participants: participants,
        isEliteOnly: isElite,
        isPublic: isPub,
      ),
    );
  }

  void updateLocation(String name, String address, LatLng coords) {
    emit(
      state.copyWith(locationName: name, address: address, coordinates: coords),
    );
  }

  void initForEdit(Map<String, dynamic> event) {
    // Optional: load existing event data to states here
  }

  Future<void> submitEvent({Map<String, dynamic> extraData = const {}}) async {
    emit(state.copyWith(isSubmitting: true, error: null));
    try {
      final payload = {
        'title': state.title,
        'category': state.category,
        'participants': state.participants,
        'date': state.date,
        'time': '${state.time?.hour}:${state.time?.minute}',
        'locationName': state.locationName,
        'location': state.address,
        'isEliteOnly': state.isEliteOnly,
        'isPublic': state.isPublic,
        'vibeTags': state.vibeTags.join(', '),
      };
      await _apiService.createEvent({...payload, ...extraData});
      emit(state.copyWith(isSubmitting: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, error: e.toString()));
    }
  }
}
