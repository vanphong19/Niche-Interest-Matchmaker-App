import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class SocialAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  Future<Map<String, String>?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return null;

      final GoogleSignInAuthentication auth = await account.authentication;

      return {
        'provider': 'google',
        'email': account.email,
        'displayName': account.displayName ?? '',
        'providerId': account.id,
        'token': auth.idToken ?? '',
      };
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  Future<Map<String, String>?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );

      if (result.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData();
        return {
          'provider': 'facebook',
          'email': userData['email']?.toString() ?? '',
          'displayName': userData['name']?.toString() ?? '',
          'providerId': userData['id']?.toString() ?? '',
          'token': result.accessToken?.tokenString ?? '',
        };
      } else if (result.status == LoginStatus.cancelled) {
        return null;
      } else {
        throw Exception('Facebook Login failed: ${result.message}');
      }
    } catch (e) {
      throw Exception('Facebook Login failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
  }
}
