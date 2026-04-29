// lib/features/event/presentation/bloc/event_detail_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../data/services/event_api_service.dart';
import '../../domain/entities/event.dart';

abstract class EventDetailState {}

class EventDetailInitial extends EventDetailState {}

class EventDetailLoading extends EventDetailState {}

class EventDetailLoaded extends EventDetailState {
  final Event event;
  final bool isJoining;
  final String? error;

  EventDetailLoaded({required this.event, this.isJoining = false, this.error});

  EventDetailLoaded copyWith({Event? event, bool? isJoining, String? error}) {
    return EventDetailLoaded(
      event: event ?? this.event,
      isJoining: isJoining ?? this.isJoining,
      error: error,
    );
  }
}

class EventDetailError extends EventDetailState {
  final String message;
  EventDetailError(this.message);
}

@injectable
class EventDetailCubit extends Cubit<EventDetailState> {
  final EventApiService _apiService;

  EventDetailCubit(this._apiService) : super(EventDetailInitial());

  Future<void> loadEvent(String id) async {
    emit(EventDetailLoading());
    try {
      final event = await _apiService.getEventDetail(id);
      emit(EventDetailLoaded(event: event));
    } catch (e) {
      emit(EventDetailError(e.toString()));
    }
  }

  Future<void> toggleJoinLeave() async {
    final currentState = state;
    if (currentState is EventDetailLoaded) {
      emit(currentState.copyWith(isJoining: true, error: null));
      try {
        Event updatedEvent;
        if (currentState.event.isJoined) {
          updatedEvent = await _apiService.leaveEvent(currentState.event.id);
        } else {
          updatedEvent = await _apiService.joinEvent(currentState.event.id);
        }
        emit(currentState.copyWith(event: updatedEvent, isJoining: false));
      } catch (e) {
        emit(currentState.copyWith(isJoining: false, error: e.toString()));
      }
    }
  }
}
