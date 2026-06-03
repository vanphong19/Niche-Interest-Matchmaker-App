import 'package:flutter_test/flutter_test.dart';
import 'package:niche_interest_matchmaker_app/app.dart';
import 'package:niche_interest_matchmaker_app/features/auth/domain/entities/auth_user.dart';
import 'package:niche_interest_matchmaker_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:niche_interest_matchmaker_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:niche_interest_matchmaker_app/injection/injection_container.dart';
import 'package:get_it/get_it.dart';

void main() {
  setUpAll(() async {
    await GetIt.instance.reset();
    sl.registerFactory<AuthBloc>(() => AuthBloc(_FakeAuthRepository()));
  });

  tearDownAll(() async {
    await GetIt.instance.reset();
  });

  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const VibeApp());
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('VibePulse'), findsOneWidget);

    // Wait for the 2-second navigation timer in SplashPage to complete
    await tester.pump(const Duration(seconds: 2));
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthUser?> getCurrentUser() async => null;

  @override
  Future<String?> getToken() async => null;

  @override
  Future<void> saveToken(String token, String refreshToken) async {}

  @override
  Future<AuthUser> signInWithEmailAndPassword(String email, String password) {
    throw UnimplementedError();
  }

  @override
  Future<AuthUser> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
    String verificationCode,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendSignUpOtp(String email) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<String> login(String email, String password) async => 'token';

  @override
  Future<void> logout() async {}

  @override
  Future<AuthUser> loginWithSocial(
    String provider,
    String email,
    String displayName,
    String providerId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {}

  @override
  Future<void> forgotPassword(String email) async {}

  @override
  Future<void> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {}
}
