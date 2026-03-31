import 'package:flutter_bloc/flutter_bloc.dart';

import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeState.initial());

  Future<void> loadModules() async {
    emit(
      state.copyWith(
        loading: false,
        modules: const ['Auth', 'Home', 'Settings'],
      ),
    );
  }
}
