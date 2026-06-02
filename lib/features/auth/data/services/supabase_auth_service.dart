import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service that handles Google authentication via Supabase Auth.
///
/// Android uses Supabase OAuth redirect so Google login does not depend on
/// google-services.json OAuth client resources.
class SupabaseAuthService {
  static const String _mobileOAuthRedirectUrl = 'vibepulse://login-callback';

  // Lazy initialization to avoid assertion error on Web startup
  GoogleSignIn get _googleSignIn {
    return GoogleSignIn(
      scopes: ['email', 'profile'],
      // clientId: Bắt buộc trên Web/iOS. Trên Android phải để null để Google tự động nhận diện qua SHA-1.
      clientId: (kIsWeb || defaultTargetPlatform == TargetPlatform.iOS)
          ? '31146531682-o6qjjahltbfbnsh94504sialqcpsb6m9.apps.googleusercontent.com'
          : null,
      // serverClientId: Bắt buộc trên Android để lấy idToken cho Supabase (Dùng Web Client ID)
      serverClientId:
          '31146531682-o6qjjahltbfbnsh94504sialqcpsb6m9.apps.googleusercontent.com',
    );
  }

  SupabaseClient get _supabase => Supabase.instance.client;

  /// Authenticates via Google → Supabase Auth.
  /// Returns user info map or null if cancelled.
  Future<Map<String, String>?> signInWithGoogle() async {
    try {
      // 1. On Web, bypass google_sign_in SDK completely to avoid JS/CORS/403 issues.
      // Use native Supabase OAuth redirect.
      if (kIsWeb) {
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: Uri
              .base
              .origin, // Redirect về đúng port hiện tại của Flutter Web thay vì Site URL mặc định của Supabase
        );
        // The browser will redirect. Delay forever to keep the loading spinner active.
        await Future.delayed(const Duration(days: 1));
        return null;
      }

      // 2. On Android, use Supabase OAuth browser redirect instead of the
      // GoogleSignIn SDK so google-services.json cannot affect idToken config.
      if (defaultTargetPlatform == TargetPlatform.android) {
        return await _signInWithSupabaseOAuthRedirect();
      }

      // 3. On iOS, use Google Sign-In SDK for native popup
      // Gọi signOut trước để xóa cache kẹt (Fix lỗi popup bật lên rồi tắt luôn)
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception(
          'Google Sign-In trả về null (Lỗi cấu hình hoặc người dùng hủy)',
        );
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Không thể lấy Google ID Token');
      }

      AuthResponse response;
      try {
        response = await _supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );
      } catch (innerError) {
        throw Exception('SUPABASE BÁO LỖI: ${innerError.toString()}');
      }

      final supabaseUser = response.user;
      if (supabaseUser == null) {
        throw Exception('Xác thực Supabase không thành công');
      }

      // 3. Extract user info to pass to backend
      final metadata = supabaseUser.userMetadata ?? {};
      return {
        'provider': 'google',
        'email': supabaseUser.email ?? googleUser.email,
        'displayName':
            metadata['full_name']?.toString() ??
            metadata['name']?.toString() ??
            googleUser.displayName ??
            '',
        'providerId': supabaseUser.id,
        'avatarUrl':
            metadata['avatar_url']?.toString() ??
            metadata['picture']?.toString() ??
            '',
      };
    } catch (e) {
      // Re-throw with readable message
      final msg = e.toString();
      if (msg.contains('sign_in_canceled') ||
          msg.contains('CANCELED') ||
          msg.contains('cancelled')) {
        return null; // User cancelled, not an error
      }
      throw Exception('Đăng nhập Google thất bại: $e');
    }
  }

  Future<Map<String, String>?> _signInWithSupabaseOAuthRedirect() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {}

    final authState = _supabase.auth.onAuthStateChange.firstWhere(
      (state) =>
          state.event == AuthChangeEvent.signedIn && state.session != null,
    );

    final launched = await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _mobileOAuthRedirectUrl,
    );
    if (!launched) {
      throw Exception('Không thể mở trình duyệt để đăng nhập Google');
    }

    final currentSession = _supabase.auth.currentSession;
    final session =
        currentSession ??
        (await authState.timeout(
          const Duration(seconds: 90),
          onTimeout: () {
            throw Exception(
              'Không nhận được phiên đăng nhập từ Supabase OAuth. '
              'Kiểm tra redirect URL $_mobileOAuthRedirectUrl trong Supabase.',
            );
          },
        )).session;

    final user = session?.user;
    if (user == null) {
      throw Exception('Xác thực Supabase không thành công');
    }

    return _mapSupabaseUser(user);
  }

  Map<String, String> _mapSupabaseUser(User supabaseUser) {
    final metadata = supabaseUser.userMetadata ?? {};
    return {
      'provider': 'google',
      'email': supabaseUser.email ?? '',
      'displayName':
          metadata['full_name']?.toString() ??
          metadata['name']?.toString() ??
          '',
      'providerId': supabaseUser.id,
      'avatarUrl':
          metadata['avatar_url']?.toString() ??
          metadata['picture']?.toString() ??
          '',
    };
  }

  /// Signs out from both Google and Supabase
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await _supabase.auth.signOut();
    } catch (_) {}
  }
}
