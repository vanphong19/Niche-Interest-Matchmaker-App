// lib/features/event/presentation/bloc/event_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../data/services/event_api_service.dart';
import '../../domain/entities/event.dart';

const Object _unset = Object();

abstract class EventEvent {}

class LoadEvents extends EventEvent {
  final String? category;
  final bool isRefresh;
  LoadEvents({this.category, this.isRefresh = true});
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
  final bool hasReachedMax;
  final String? error;

  EventState({
    this.events = const [],
    this.hosting = const [],
    this.joined = const [],
    this.past = const [],
    this.selectedCategory,
    this.isLoading = false,
    this.hasReachedMax = false,
    this.error,
  });

  EventState copyWith({
    List<Event>? events,
    List<Event>? hosting,
    List<Event>? joined,
    List<Event>? past,
    Object? selectedCategory = _unset,
    bool? isLoading,
    bool? hasReachedMax,
    String? error,
  }) {
    return EventState(
      events: events ?? this.events,
      hosting: hosting ?? this.hosting,
      joined: joined ?? this.joined,
      past: past ?? this.past,
      selectedCategory: selectedCategory == _unset
          ? this.selectedCategory
          : selectedCategory as String?,
      isLoading: isLoading ?? this.isLoading,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      error: error ?? this.error,
    );
  }
}

@injectable
class EventBloc extends Bloc<EventEvent, EventState> {
  final EventApiService _apiService;
  int _loadVersion = 0;

  EventBloc(this._apiService) : super(EventState()) {
    on<LoadEvents>(_onLoadEvents);
    on<SearchEvents>(_onSearchEvents);
    on<LoadMyEvents>(_onLoadMyEvents);
  }

  Future<void> _onLoadEvents(LoadEvents event, Emitter<EventState> emit) async {
    if (state.isLoading || (!event.isRefresh && state.hasReachedMax)) return;

    final version = ++_loadVersion;
    final selectedCategory = event.category;

    if (event.isRefresh) {
      emit(
        state.copyWith(
          selectedCategory: selectedCategory,
          isLoading: true,
          error: null,
          hasReachedMax: false,
          events: [],
        ),
      );
    } else {
      emit(state.copyWith(isLoading: true, error: null));
    }

    try {
      final offset = event.isRefresh ? 0 : state.events.length;
      const limit = 10;

      final events = await _apiService.getEvents(
        category: selectedCategory,
        limit: limit,
        offset: offset,
      );

      // Automatically load my events too to keep stats in sync
      final myEvents = await _apiService.getMyEvents();
      if (version != _loadVersion || emit.isDone) return;

      final currentEvents = event.isRefresh
          ? <Event>[]
          : List<Event>.from(state.events);
      currentEvents.addAll(events);

      emit(
        state.copyWith(
          events: currentEvents,
          hosting: myEvents['hosting'] ?? [],
          joined: myEvents['joined'] ?? [],
          past: myEvents['past'] ?? [],
          selectedCategory: selectedCategory,
          isLoading: false,
          hasReachedMax: events.length < limit,
        ),
      );
    } catch (e) {
      if (version != _loadVersion || emit.isDone) return;
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
