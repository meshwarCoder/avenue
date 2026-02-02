import 'dart:ffi';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:line/core/di/injection_container.dart';
import 'package:line/core/utils/routes.dart';
import 'package:line/features/schdules/presentation/cubit/task_cubit.dart';
import 'package:line/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';
import 'package:line/core/utils/constants.dart';
import 'package:line/features/schdules/domain/repo/schedule_repository.dart';
import 'package:line/core/logic/theme_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    if (Platform.isLinux) {
      open.overrideFor(OperatingSystem.linux, () {
        return DynamicLibrary.open('libsqlite3.so.0');
      });
    }
    // Initialize sqflite for desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize all dependencies (Hive, repositories, etc.)
  await initializeDependencies();

  // Prune old tasks (keep 1 week history locally)
  try {
    final retentionDate = DateTime.now().subtract(const Duration(days: 7));
    await sl<ScheduleRepository>().deleteTasksBefore(retentionDate);
    print("Pruned local tasks older than $retentionDate");
  } catch (e) {
    print("Failed to prune old tasks: $e");
  }

  runApp(const Line());
}

class Line extends StatelessWidget {
  const Line({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<AuthCubit>()),
        BlocProvider(create: (context) => sl<TaskCubit>()),
        BlocProvider(create: (context) => sl<ThemeCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'Avenue',
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.deepPurple,
                primary: AppColors.deepPurple,
                secondary: AppColors.slatePurple,
                tertiary: AppColors.creamTan,
                surface: AppColors.lightBg,
                background: AppColors.lightBg,
              ),
              scaffoldBackgroundColor: AppColors.lightBg,
              cardColor: Colors.white,
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.lightBg,
                foregroundColor: AppColors.deepPurple,
                elevation: 0,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                brightness: Brightness.dark,
                seedColor: AppColors.deepPurple,
                primary: AppColors.slatePurple,
                secondary: AppColors.deepPurple,
                tertiary: AppColors.salmonPink,
                surface: AppColors.darkBg,
                background: AppColors.darkBg,
              ),
              scaffoldBackgroundColor: AppColors.darkBg,
              cardColor: const Color(
                0xFF1E1E1E,
              ), // Slightly lighter than background for depth
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.darkBg,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
            routerConfig: AppRoutes.router,
          );
        },
      ),
    );
  }
}
