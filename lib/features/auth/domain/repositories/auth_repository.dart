import '../entities/auth_user.dart';

abstract class AuthRepository {
  Future<AuthUser> signInWithEmailAndPassword(String email, String password);
  Future<AuthUser> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  );
  Future<void> signOut();
  Future<AuthUser?> getCurrentUser();

  // existing required by network/other things maybe
  Future<String?> getToken();
  Future<void> saveToken(String token, String refreshToken);
  Future<String> login(String email, String password);
  Future<void> logout();
  Future<AuthUser> loginWithSocial(String provider, String email, String displayName, String providerId);
}
