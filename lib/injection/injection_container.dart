import 'package:get_it/get_it.dart';
import '../router/app_router.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ─── Core & Router ──────────────────────────────────────
  sl.registerLazySingleton<AppRouter>(() => AppRouter());

  // ─── Network (ví dụ: Dio) ───────────────────────────────
  // sl.registerLazySingleton<Dio>(() => Dio());

  // ─── Features ───────────────────────────────────────────
  // Thêm các dependencies cho feature của bạn ở đây sau
}
