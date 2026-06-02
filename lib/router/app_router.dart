// lib/router/app_router.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import '../core/constants/app_constants.dart';
import 'app_router.gr.dart';

@LazySingleton()
@AutoRouterConfig(replaceInRouteName: 'Page|Screen,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const RouteType.adaptive();

  @override
  List<AutoRoute> get routes => [
    // ─── Auth Flow ────────────────────────────────────────────
    AutoRoute(page: SplashRoute.page, path: '/', initial: true),
    AutoRoute(page: LoginRoute.page, path: '/login'),
    AutoRoute(page: RegisterRoute.page, path: '/register'),
    AutoRoute(page: ForgotPasswordRoute.page, path: '/forgot-password'),

    // ─── Main App Shell ───────────────────────────────────────
    AutoRoute(
      page: BaseRoute.page,
      path: '/base',
      children: [
        AutoRoute(page: HomeRoute.page, path: 'home', initial: true),
        AutoRoute(page: VibeMatchRoute.page, path: 'match'),
        AutoRoute(page: ChatInboxRoute.page, path: 'messages'),
        AutoRoute(page: ProfileRoute.page, path: 'profile'),
      ],
    ),

    // ─── Event Routes ─────────────────────────────────────────
    AutoRoute(page: CreateEventRoute.page, path: '/event/create'),
    AutoRoute(page: EventDetailRoute.page, path: '/event/:id'),
    AutoRoute(page: ManageEventRoute.page, path: '/event/:id/manage'),
    AutoRoute(page: EditEventRoute.page, path: '/event/:id/edit'),
    AutoRoute(page: UserMatchListRoute.page, path: '/match/list'),
    AutoRoute(page: MapDiscoveryRoute.page, path: '/map'),

    // Check-in UI Routes
    AutoRoute(page: CheckinDetailRoute.page, path: '/checkin'),
    AutoRoute(page: CheckinMethodRoute.page, path: '/checkin/method'),
    AutoRoute(page: QrCheckinScannerRoute.page, path: '/checkin/qr'),
    AutoRoute(page: CheckinVerifyingRoute.page, path: '/checkin/verifying'),
    AutoRoute(page: NfcCheckinWaitingRoute.page, path: '/checkin/nfc'),
    AutoRoute(page: NfcCheckinResultRoute.page, path: '/checkin/nfc/result'),
    AutoRoute(page: TrustProfileRoute.page, path: '/checkin/trust'),

    // Find In Crowd UI Routes
    AutoRoute(page: FindInCrowdMeetingRoute.page, path: '/find-in-crowd'),
    AutoRoute(page: FinderStartRoute.page, path: '/find-in-crowd/start'),
    AutoRoute(page: FinderWaitingRoute.page, path: '/find-in-crowd/waiting'),
    AutoRoute(
      page: FinderIncomingRequestRoute.page,
      path: '/find-in-crowd/request',
    ),
    AutoRoute(page: FinderRadarRoute.page, path: '/find-in-crowd/radar'),
    AutoRoute(page: FinderNearbyRoute.page, path: '/find-in-crowd/nearby'),
    AutoRoute(page: FinderCameraRoute.page, path: '/find-in-crowd/camera'),
    AutoRoute(
      page: FinderStopConfirmationRoute.page,
      path: '/find-in-crowd/stop',
    ),
    AutoRoute(page: FinderEndedRoute.page, path: '/find-in-crowd/ended'),

    // ─── Settings ─────────────────────────────────────────────
    AutoRoute(page: SettingsRoute.page, path: '/settings'),
    AutoRoute(
      page: ChangePasswordRoute.page,
      path: '/settings/change-password',
    ),
    AutoRoute(page: HelpCenterRoute.page, path: '/settings/help-center'),
    AutoRoute(
      page: TermsOfServiceRoute.page,
      path: '/settings/terms-of-service',
    ),
    AutoRoute(page: PrivacyPolicyRoute.page, path: '/settings/privacy-policy'),

    // ─── Profile Edit & View ───────────────────────────────────
    AutoRoute(page: EditProfileRoute.page, path: '/profile/edit'),
    AutoRoute(page: LocationPickerRoute.page, path: '/profile/location-picker'),
    AutoRoute(page: OtherUserProfileRoute.page, path: '/profile/:id'),
    AutoRoute(page: AllActivityHistoryRoute.page, path: '/profile/history'),

    // ─── Vibe Check ───────────────────────────────────────────
    AutoRoute(page: VibeCheckResultRoute.page, path: '/vibe-check'),

    // Public profile slug, e.g. http://localhost:xxxx/namle
    AutoRoute(page: PublicProfileRoute.page, path: '/:id'),
  ];

  @override
  List<AutoRouteGuard> get guards => [
    // AuthGuard can be added here when ready
  ];
}

@LazySingleton()
class AppRouterProvider {
  static final AppRouter _instance = AppRouter();
  static AppRouter get instance => _instance;
}

/// Auth guard that checks for valid token before allowing navigation.
class AuthGuard extends AutoRouteGuard {
  final FlutterSecureStorage _secureStorage;

  AuthGuard({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) async {
    final token = await _secureStorage.read(key: AppConstants.tokenKey);

    if (token != null && token.isNotEmpty) {
      resolver.next(true);
    } else {
      router.replaceAll([const LoginRoute()]);
      resolver.next(false);
    }
  }
}
