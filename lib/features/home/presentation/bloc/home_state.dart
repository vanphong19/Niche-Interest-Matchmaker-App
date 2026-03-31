import 'package:equatable/equatable.dart';

class HomeState extends Equatable {
  const HomeState({required this.loading, required this.modules});

  factory HomeState.initial() {
    return const HomeState(loading: true, modules: []);
  }

  final bool loading;
  final List<String> modules;

  HomeState copyWith({bool? loading, List<String>? modules}) {
    return HomeState(
      loading: loading ?? this.loading,
      modules: modules ?? this.modules,
    );
  }

  @override
  List<Object?> get props => [loading, modules];
}
