// lib/injection/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/network/dio_client.dart';
import '../core/network/network_info.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/data/services/social_auth_service.dart';
import '../features/auth/data/services/supabase_auth_service.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/settings/presentation/bloc/settings_bloc.dart';
import '../features/vibe_check/presentation/bloc/vibe_match_bloc.dart';
import '../features/vibe_check/presentation/bloc/vibe_check_bloc.dart';
import '../features/vibe_check/presentation/bloc/group_vibe_check_bloc.dart';
import '../features/vibe_check/data/datasources/vibe_check_remote_data_source.dart';
import '../features/vibe_check/data/repositories/vibe_check_repository_impl.dart';
import '../features/vibe_check/domain/repositories/vibe_check_repository.dart';
import '../router/app_router.dart';
import '../core/services/push_notification_service.dart';
import '../core/services/signalr_service.dart';

import '../features/event/data/services/event_api_service.dart'
    as import_event_api;
import '../features/checkin/data/datasources/checkin_remote_data_source.dart';
import '../features/checkin/data/repositories/checkin_repository_impl.dart';
import '../features/checkin/data/services/nfc_payload_parser.dart';
import '../features/checkin/domain/repositories/checkin_repository.dart';
import '../features/checkin/domain/strategies/check_in_strategy.dart';
import '../features/checkin/domain/usecases/check_in_usecase.dart';
import '../features/checkin/domain/usecases/check_in_with_strategy_usecase.dart';
import '../features/checkin/domain/usecases/check_in_with_nfc_usecase.dart';
import '../features/checkin/domain/usecases/get_checkin_eligibility_usecase.dart';
import '../features/checkin/presentation/bloc/checkin_bloc.dart';
import '../features/event/presentation/bloc/event_bloc.dart'
    as import_event_bloc;
import '../features/event/presentation/bloc/create_event_cubit.dart'
    as import_create_event;
import '../features/event/presentation/bloc/event_detail_cubit.dart'
    as import_event_detail;
import '../features/profile/data/services/user_api_service.dart'
    as import_user_api;
<<<<<<< HEAD
=======
import '../features/trust/data/services/reputation_api_service.dart';
>>>>>>> realtimechat
import '../features/chat/data/services/chat_api_service.dart';
import '../features/chat/data/services/signalr_chat_service.dart';
import '../features/chat/presentation/cubit/chat_cubit.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  // ─── External ─────────────────────────────────────────────────
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  // ─── Core ─────────────────────────────────────────────────────
  sl.registerLazySingleton<DioClient>(
    () => DioClient(secureStorage: sl<FlutterSecureStorage>()),
  );
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  sl.registerLazySingleton<SignalRService>(
    () => SignalRService(sl<FlutterSecureStorage>()),
  );

  // ─── Router ───────────────────────────────────────────────────
  sl.registerLazySingleton<AppRouter>(() => AppRouter());

  // ─── Auth Feature ─────────────────────────────────────────────
  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<DioClient>().dio),
  );
  sl.registerLazySingleton<SocialAuthService>(() => SocialAuthService());
  sl.registerLazySingleton<SupabaseAuthService>(() => SupabaseAuthService());

  // Bloc
  sl.registerFactory<AuthBloc>(() => AuthBloc(sl<AuthRepository>()));

  // ─── Settings Feature ─────────────────────────────────────────
  sl.registerFactory<SettingsBloc>(() => SettingsBloc());

  // ─── Vibe Match Feature ───────────────────────────────────────
  sl.registerFactory<VibeMatchBloc>(() => VibeMatchBloc());

  // ─── Vibe Check Feature ───────────────────────────────────────
  sl.registerLazySingleton<VibeCheckRemoteDataSource>(
    () => VibeCheckRemoteDataSource(sl<DioClient>()),
  );
  sl.registerLazySingleton<VibeCheckRepository>(
    () => VibeCheckRepositoryImpl(sl<VibeCheckRemoteDataSource>()),
  );
  sl.registerFactory<VibeCheckBloc>(
    () => VibeCheckBloc(sl<VibeCheckRepository>()),
  );
  sl.registerFactory<GroupVibeCheckBloc>(
    () => GroupVibeCheckBloc(sl<VibeCheckRepository>()),
  );

  // ─── Event Feature ────────────────────────────────────────────
  sl.registerLazySingleton<import_event_api.EventApiService>(
    () => import_event_api.EventApiService(sl<DioClient>().dio),
  );
  sl.registerLazySingleton<import_event_bloc.EventBloc>(
    () => import_event_bloc.EventBloc(sl<import_event_api.EventApiService>()),
  );
  sl.registerFactory<import_create_event.CreateEventCubit>(
    () => import_create_event.CreateEventCubit(
      sl<import_event_api.EventApiService>(),
    ),
  );
  sl.registerFactory<import_event_detail.EventDetailCubit>(
    () => import_event_detail.EventDetailCubit(
      sl<import_event_api.EventApiService>(),
    ),
  );

  // ─── Profile Feature ──────────────────────────────────────────
  sl.registerLazySingleton<import_user_api.UserApiService>(
    () => import_user_api.UserApiService(sl<DioClient>().dio),
  );
<<<<<<< HEAD
  sl.registerLazySingleton<PushNotificationService>(
    () => PushNotificationService(sl<import_user_api.UserApiService>()),
=======
  sl.registerLazySingleton<ReputationApiService>(
    () => ReputationApiService(sl<DioClient>().dio),
  );
  sl.registerLazySingleton<PushNotificationService>(
    () => PushNotificationService(
      sl<import_user_api.UserApiService>(),
      sl<ChatApiService>(),
    ),
>>>>>>> realtimechat
  );

  // Check-in Feature
  sl.registerLazySingleton<NfcPayloadParser>(() => NfcPayloadParser());
  sl.registerLazySingleton<CheckinRemoteDataSource>(
    () => CheckinRemoteDataSource(sl<DioClient>().dio),
  );
  sl.registerLazySingleton<CheckinRepository>(
    () => CheckinRepositoryImpl(
      remoteDataSource: sl<CheckinRemoteDataSource>(),
      nfcPayloadParser: sl<NfcPayloadParser>(),
    ),
  );
  sl.registerLazySingleton<QrCheckInStrategy>(
    () => QrCheckInStrategy(sl<CheckinRepository>()),
  );
  sl.registerLazySingleton<NfcCheckInStrategy>(
    () => NfcCheckInStrategy(sl<CheckinRepository>()),
  );
  sl.registerLazySingleton<CheckInStrategyRegistry>(
    () => CheckInStrategyRegistry([
      sl<QrCheckInStrategy>(),
      sl<NfcCheckInStrategy>(),
    ]),
  );
  sl.registerLazySingleton<GetCheckinEligibilityUseCase>(
    () => GetCheckinEligibilityUseCase(sl<CheckinRepository>()),
  );
  sl.registerLazySingleton<CheckInWithStrategyUseCase>(
    () => CheckInWithStrategyUseCase(sl<CheckInStrategyRegistry>()),
  );
  sl.registerLazySingleton<CheckInWithNfcUseCase>(
    () => CheckInWithNfcUseCase(sl<NfcCheckInStrategy>()),
  );
  sl.registerLazySingleton<CheckInUseCase>(
    () => CheckInUseCase(sl<CheckinRepository>()),
  );
  sl.registerFactory<CheckinBloc>(
    () => CheckinBloc(
      checkInWithStrategyUseCase: sl<CheckInWithStrategyUseCase>(),
      getEligibilityUseCase: sl<GetCheckinEligibilityUseCase>(),
    ),
  );

  // Chat Feature
  sl.registerLazySingleton<ChatApiService>(
    () => ChatApiService(sl<DioClient>().dio),
  );
  sl.registerLazySingleton<SignalRChatService>(
    () => SignalRChatService(sl<FlutterSecureStorage>()),
  );
  sl.registerFactory<ChatCubit>(
    () => ChatCubit(sl<ChatApiService>(), sl<SignalRChatService>()),
  );
}
