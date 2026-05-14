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

class EventState {
  final List<Event> events;
  final List<Event> hosting;
  final List<Event> joined;
  final List<Event> past;
  final String? selectedCategory;
  final bool isLoading;
  final String? error;

  EventState({
    this.events = const [],
    this.hosting = const [],
    this.joined = const [],
    this.past = const [],
    this.selectedCategory,
    this.isLoading = false,
    this.error,
  });

  EventState copyWith({
    List<Event>? events,
    List<Event>? hosting,
    List<Event>? joined,
    List<Event>? past,
    String? selectedCategory,
    bool? isLoading,
    String? error,
  }) {
    return EventState(
      events: events ?? this.events,
      hosting: hosting ?? this.hosting,
      joined: joined ?? this.joined,
      past: past ?? this.past,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

@injectable
class EventBloc extends Bloc<EventEvent, EventState> {
  final EventApiService _apiService;

  EventBloc(this._apiService) : super(EventState()) {
    on<LoadEvents>(_onLoadEvents);
    on<SearchEvents>(_onSearchEvents);
    on<LoadMyEvents>(_onLoadMyEvents);
  }

  Future<void> _onLoadEvents(LoadEvents event, Emitter<EventState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final events = await _apiService.getEvents(category: event.category);
      // Automatically load my events too to keep stats in sync
      final myEvents = await _apiService.getMyEvents();

      emit(
        state.copyWith(
          events: events,
          hosting: myEvents['hosting'] ?? [],
          joined: myEvents['joined'] ?? [],
          past: myEvents['past'] ?? [],
          selectedCategory: event.category,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onSearchEvents(
    SearchEvents event,
    Emitter<EventState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
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
      emit(state.copyWith(events: filtered, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLoadMyEvents(
    LoadMyEvents event,
    Emitter<EventState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final result = await _apiService.getMyEvents();
      emit(
        state.copyWith(
          hosting: result['hosting'] ?? [],
          joined: result['joined'] ?? [],
          past: result['past'] ?? [],
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
