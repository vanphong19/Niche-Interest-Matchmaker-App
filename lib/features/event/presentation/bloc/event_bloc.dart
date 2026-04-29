// lib/features/event/presentation/bloc/event_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../data/services/event_api_service.dart';
import '../../domain/entities/event.dart';

abstract class EventEvent {}

class LoadEvents extends EventEvent {
  final String? category;
  LoadEvents({this.category});
}

class SearchEvents extends EventEvent {
  final String query;
  SearchEvents(this.query);
}

class LoadMyEvents extends EventEvent {}

abstract class EventState {}

class EventInitial extends EventState {}

class EventLoading extends EventState {}

class EventLoaded extends EventState {
  final List<Event> events;
  final String? selectedCategory;

  EventLoaded(this.events, {this.selectedCategory});
}

class MyEventsLoaded extends EventState {
  final List<Event> hosting;
  final List<Event> joined;
  final List<Event> past;

  MyEventsLoaded({required this.hosting, required this.joined, required this.past});
}

class EventError extends EventState {
  final String message;
  EventError(this.message);
}

@injectable
class EventBloc extends Bloc<EventEvent, EventState> {
  final EventApiService _apiService;

  EventBloc(this._apiService) : super(EventInitial()) {
    on<LoadEvents>(_onLoadEvents);
    on<SearchEvents>(_onSearchEvents);
    on<LoadMyEvents>(_onLoadMyEvents);
  }

  Future<void> _onLoadEvents(LoadEvents event, Emitter<EventState> emit) async {
    emit(EventLoading());
    try {
      final events = await _apiService.getEvents(category: event.category);
      emit(EventLoaded(events, selectedCategory: event.category));
    } catch (e) {
      emit(EventError(e.toString()));
    }
  }

  Future<void> _onSearchEvents(SearchEvents event, Emitter<EventState> emit) async {
    emit(EventLoading());
    try {
      final events = await _apiService.getEvents();
      final q = event.query.toLowerCase();
      final filtered = events.where((e) {
        return e.title.toLowerCase().contains(q) ||
            e.categoryName.toLowerCase().contains(q) ||
            (e.vibeTags?.toLowerCase().contains(q) ?? false) ||
            e.location.name.toLowerCase().contains(q) ||
            e.location.address.toLowerCase().contains(q);
      }).toList();
      emit(EventLoaded(filtered));
    } catch (e) {
      emit(EventError(e.toString()));
    }
  }

  Future<void> _onLoadMyEvents(LoadMyEvents event, Emitter<EventState> emit) async {
    emit(EventLoading());
    try {
      final result = await _apiService.getMyEvents();
      emit(MyEventsLoaded(
        hosting: result['hosting'] ?? [],
        joined: result['joined'] ?? [],
        past: result['past'] ?? [],
      ));
    } catch (e) {
      emit(EventError(e.toString()));
    }
  }
}
