import '../../features/ai/ai/ai_orchestrator.dart';
import 'package:get_it/get_it.dart';
import '../../features/schdules/data/datasources/task_local_data_source.dart';
import '../../features/schdules/data/datasources/task_local_data_source_impl.dart';
import '../../features/schdules/data/repo/schedule_repo_impl.dart';
import '../../features/schdules/domain/repo/schedule_repository.dart';
import '../../features/schdules/presentation/cubit/task_cubit.dart';
import '../../features/schdules/presentation/cubit/default_tasks_cubit.dart';
import '../../features/ai/presentation/logic/chat_cubit.dart';
import '../services/embedding_service.dart';
import '../../features/weeks/domain/repo/weekly_repository.dart';
import '../../features/weeks/data/repo/weekly_repo_impl.dart';
import '../../features/weeks/presentation/cubit/weekly_cubit.dart';
import '../services/device_service.dart';
import '../services/local_notification_service.dart';
import '../services/task_notification_manager.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/sync_service.dart';
import '../services/database_service.dart';

import '../../features/auth/data/repo/auth_repository_impl.dart';
import '../../features/auth/domain/repo/auth_repository.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../logic/theme_cubit.dart';
import '../../features/ai/data/repositories/chat_repository.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Register DatabaseService
  final databaseService = DatabaseService();
  sl.registerLazySingleton<DatabaseService>(() => databaseService);

  // Supabase Client
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // Services
  sl.registerLazySingleton<DeviceService>(() => DeviceService());
  sl.registerLazySingleton<LocalNotificationService>(
    () => LocalNotificationService.instance,
  );
  sl.registerLazySingleton<TaskNotificationManager>(
    () => TaskNotificationManager(sl(), sl()),
  );
  sl.registerLazySingleton<SyncService>(
    () => SyncService(
      databaseService: sl(),
      supabase: sl(),
      // embeddingService: sl(), // Removed: Supabase handles embedding generation
      authRepository: sl(),
      deviceService: sl(),
      notificationManager: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<TaskLocalDataSource>(
    () => TaskLocalDataSourceImpl(databaseService: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(supabase: sl()),
  );
  sl.registerLazySingleton<ScheduleRepository>(
    () => ScheduleRepositoryImpl(
      localDataSource: sl(),
      supabase: sl(),
      embeddingService: sl(),
    ),
  );
  sl.registerLazySingleton<WeeklyRepository>(
    () => WeeklyRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepository(sl(), sl()),
  );

  // Cubits (Factory - new instance each time)
  sl.registerLazySingleton(
    () =>
        AuthCubit(repository: sl(), deviceService: sl(), databaseService: sl()),
  );
  sl.registerLazySingleton(
    () => TaskCubit(
      repository: sl(),
      syncService: sl(),
      notificationManager: sl(),
    ),
  );
  sl.registerFactory(() => WeeklyCubit(repository: sl()));
  sl.registerLazySingleton(() => ThemeCubit(sl()));
  sl.registerLazySingleton(() => SettingsCubit(sl(), sl()));
  sl.registerFactory(() => DefaultTasksCubit(sl()));

  // AI Chat
  sl.registerLazySingleton<EmbeddingService>(
    () => EmbeddingService(apiKey: dotenv.env['OPENROUTER_API_KEY'] ?? ''),
  );

  sl.registerFactory<AiOrchestrator>(
    () => AiOrchestrator(
      apiKey: dotenv.env['OPENROUTER_API_KEY'] ?? '',
      scheduleRepository: sl(),
      embeddingService: sl(),
    ),
  );

  // Chat Repository
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepository(supabase: sl(), databaseService: sl()),
  );

  sl.registerFactory(
    () =>
        ChatCubit(aiOrchestrator: sl(), chatRepository: sl(), taskCubit: sl()),
  );
}
