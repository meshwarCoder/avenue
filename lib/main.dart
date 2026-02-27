import 'dart:ffi';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avenue/core/di/injection_container.dart';
import 'package:avenue/core/utils/routes.dart';
import 'package:avenue/features/schdules/presentation/cubit/task_cubit.dart';
import 'package:avenue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';
import 'package:avenue/core/utils/constants.dart';
import 'package:avenue/core/logic/theme_cubit.dart';
import 'package:avenue/core/logic/app_connectivity_cubit.dart';
import 'package:avenue/core/widgets/offline_banner.dart';
import 'package:avenue/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:avenue/core/services/local_notification_service.dart';

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

  // Initialize Local Notifications
  await sl<LocalNotificationService>().init();

  // Initialize connectivity cubit (ensure it's created)
  sl<AppConnectivityCubit>();

  runApp(const Avenue());
}

class Avenue extends StatelessWidget {
  const Avenue({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<AuthCubit>()),
        BlocProvider(create: (context) => sl<TaskCubit>()),
        BlocProvider(create: (context) => sl<ThemeCubit>()),
        BlocProvider(create: (context) => sl<SettingsCubit>()),
        BlocProvider(create: (context) => sl<AppConnectivityCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'Avenue',
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return ConnectivityBannerWrapper(child: child!);
            },
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
