import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/sign_in_use_case.dart';
import 'auth_state.dart';

@injectable
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._signInUseCase) : super(const AuthState.initial());

  final SignInUseCase _signInUseCase;

  Future<void> signIn({required String email, required String password}) async {
    emit(const AuthState.loading());

    try {
      final user = await _signInUseCase(
        SignInParams(email: email, password: password),
      );

      emit(AuthState.authenticated(user));
    } catch (_) {
      emit(const AuthState.failure('Sign in failed. Please try again.'));
    }
  }

  void reset() {
    emit(const AuthState.initial());
  }
}
