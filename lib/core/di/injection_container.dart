import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/schdules/data/datasources/task_local_data_source.dart';
import '../../features/schdules/data/datasources/task_local_data_source_impl.dart';
import '../../features/schdules/data/models/task_model.dart';
import '../../features/schdules/data/repo/schedule_repo_impl.dart';
import '../../features/schdules/domain/repo/schedule_repository.dart';
import '../../features/schdules/presentation/cubit/task_cubit.dart';
import '../utils/constants.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapter
  Hive.registerAdapter(TaskModelAdapter());

  // Open Hive box
  final tasksBox = await Hive.openBox<TaskModel>(HiveBoxes.tasksBox);

  // Register Hive box as singleton
  sl.registerLazySingleton<Box<TaskModel>>(() => tasksBox);

  // Data sources
  sl.registerLazySingleton<TaskLocalDataSource>(
    () => TaskLocalDataSourceImpl(tasksBox: sl()),
  );

  // Repositories
  sl.registerLazySingleton<ScheduleRepository>(
    () => ScheduleRepositoryImpl(localDataSource: sl()),
  );

  // Cubits (Factory - new instance each time)
  sl.registerFactory(() => TaskCubit(repository: sl()));
}
