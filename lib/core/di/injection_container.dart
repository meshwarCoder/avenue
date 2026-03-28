import '../../features/ai/ai/ai_orchestrator.dart';
import '../../features/ai/ai/ai_repository.dart';
import 'package:get_it/get_it.dart';
import '../../features/schdules/data/datasources/task_local_data_source.dart';
import '../../features/schdules/data/datasources/task_local_data_source_impl.dart';
import '../../features/schdules/data/repo/schedule_repo_impl.dart';
import '../../features/schdules/domain/repo/schedule_repository.dart';
import '../../features/schdules/presentation/cubit/task_cubit.dart';
import '../../features/schdules/presentation/cubit/default_tasks_cubit.dart';
import '../../features/ai/presentation/logic/chat_cubit.dart';
import '../../features/weeks/presentation/cubit/weekly_cubit.dart';
import '../../features/weeks/domain/repo/weekly_repository.dart';
import '../../features/weeks/data/repo/weekly_repo_impl.dart';
import '../services/device_service.dart';
import '../services/local_notification_service.dart';
import '../services/task_notification_manager.dart';
import '../../features/inbox/data/datasources/inbox_local_data_source.dart';
import '../../features/inbox/data/datasources/inbox_local_data_source_impl.dart';
import '../../features/inbox/data/repositories/inbox_repository_impl.dart';
import '../../features/inbox/domain/repo/inbox_repository.dart';
import '../../features/inbox/presentation/cubit/inbox_cubit.dart';
import '../../features/social/data/repo/social_repository_impl.dart';
import '../../features/social/domain/repo/social_repository.dart';
import '../../features/social/presentation/cubit/social_cubit.dart';


import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/sync_service.dart';
import '../services/database_service.dart';
import '../services/network_service.dart';

import '../../features/auth/data/repo/auth_repository_impl.dart';
import '../../features/auth/domain/repo/auth_repository.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../logic/theme_cubit.dart';
import '../logic/app_connectivity_cubit.dart';
import '../logic/app_banner_cubit.dart';
import '../network/request_executor.dart';
import '../../features/ai/data/repositories/chat_repository.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/cache_helper.dart';
import '../services/ai_server_client.dart';
import '../localization/locale_repository.dart';
import '../localization/locale_repository_impl.dart';
import '../localization/locale_cubit.dart';

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
  sl.registerLazySingleton(() => CacheHelper(sl()));
  sl.registerLazySingleton(() => Connectivity());

  // Register DatabaseService
  final databaseService = DatabaseService();
  sl.registerLazySingleton<DatabaseService>(() => databaseService);

  // Supabase Client
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // Services
  sl.registerLazySingleton<NetworkService>(
    () => NetworkServiceImpl(connectivity: sl()),
  );
  sl.registerLazySingleton<RequestExecutor>(
    () => RequestExecutor(networkService: sl()),
  );
  sl.registerLazySingleton(() => AppConnectivityCubit(networkService: sl()));
  sl.registerLazySingleton(() => AppBannerCubit());
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
      authRepository: sl(),
      deviceService: sl(),
      notificationManager: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<TaskLocalDataSource>(
    () => TaskLocalDataSourceImpl(databaseService: sl()),
  );
  sl.registerLazySingleton<InboxLocalDataSource>(
    () => InboxLocalDataSourceImpl(databaseService: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(supabase: sl(), requestExecutor: sl()),
  );
  sl.registerLazySingleton<ScheduleRepository>(
    () => ScheduleRepositoryImpl(localDataSource: sl(), supabase: sl()),
  );
  sl.registerLazySingleton<WeeklyRepository>(
    () => WeeklyRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepository(sl(), sl()),
  );
  sl.registerLazySingleton<InboxRepository>(
    () => InboxRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<LocaleRepository>(() => LocaleRepositoryImpl(sl()));
  sl.registerLazySingleton<SocialRepository>(
    () => SocialRepositoryImpl(supabase: sl(), requestExecutor: sl()),
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
  sl.registerLazySingleton(() => SettingsCubit(sl(), sl(), sl()));
  sl.registerLazySingleton(() => DefaultTasksCubit(sl()));
  sl.registerLazySingleton(() => InboxCubit(repository: sl()));
  sl.registerLazySingleton(() => LocaleCubit(sl()));
  sl.registerLazySingleton(() => SocialCubit(repository: sl()));


  // AI Chat (Now using Supabase Edge Function)
  sl.registerLazySingleton<AiServerClient>(
    () => AiServerClient(supabase: sl()),
  );

  sl.registerLazySingleton<AiRepository>(
    () => AiRepository(client: sl(), scheduleRepository: sl()),
  );

  sl.registerFactory<AiOrchestrator>(() => AiOrchestrator(repository: sl()));

  // Chat Repository
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepository(supabase: sl(), databaseService: sl()),
  );

  sl.registerFactory(
    () => ChatCubit(
      aiOrchestrator: sl(),
      chatRepository: sl(),
      taskCubit: sl(),
      networkService: sl(),
    ),
  );
}
