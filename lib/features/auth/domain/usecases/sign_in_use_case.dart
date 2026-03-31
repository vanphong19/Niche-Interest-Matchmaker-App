import 'package:injectable/injectable.dart';

import '../../../../core/usecases/use_case.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class SignInParams {
  const SignInParams({required this.email, required this.password});

  final String email;
  final String password;
}

@lazySingleton
class SignInUseCase implements UseCase<AuthUser, SignInParams> {
  SignInUseCase(this._authRepository);

  final AuthRepository _authRepository;

  @override
  Future<AuthUser> call(SignInParams params) {
    return _authRepository.signIn(
      email: params.email,
      password: params.password,
    );
  }
}
