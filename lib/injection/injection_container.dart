// lib/injection/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/network/dio_client.dart';
import '../core/network/network_info.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/settings/presentation/bloc/settings_bloc.dart';
import '../features/vibe_check/presentation/bloc/vibe_match_bloc.dart';
import '../router/app_router.dart';

import '../features/event/data/services/event_api_service.dart'
    as import_event_api;
import '../features/event/presentation/bloc/event_bloc.dart'
    as import_event_bloc;
import '../features/event/presentation/bloc/create_event_cubit.dart'
    as import_create_event;
import '../features/event/presentation/bloc/event_detail_cubit.dart'
    as import_event_detail;

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

  // ─── Router ───────────────────────────────────────────────────
  sl.registerLazySingleton<AppRouter>(() => AppRouter());

  // ─── Auth Feature ─────────────────────────────────────────────
  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<DioClient>().dio),
  );

  // Bloc
  sl.registerFactory<AuthBloc>(() => AuthBloc());

  // ─── Settings Feature ─────────────────────────────────────────
  sl.registerFactory<SettingsBloc>(() => SettingsBloc());

  // ─── Vibe Match Feature ───────────────────────────────────────
  sl.registerFactory<VibeMatchBloc>(() => VibeMatchBloc());

  // ─── Event Feature ────────────────────────────────────────────
  sl.registerLazySingleton<import_event_api.EventApiService>(
    () => import_event_api.EventApiService(sl<DioClient>().dio),
  );
  sl.registerFactory<import_event_bloc.EventBloc>(
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
}
