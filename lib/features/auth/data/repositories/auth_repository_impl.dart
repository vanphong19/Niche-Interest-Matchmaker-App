import 'package:injectable/injectable.dart';

import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final model = await _remoteDataSource.signIn(
      email: email,
      password: password,
    );

    return model.toEntity();
  }
}
