import 'package:avenue/core/di/injection_container.dart';
import 'package:avenue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:avenue/features/auth/presentation/cubit/auth_state.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/roots.dart';
import '../../features/auth/presentation/views/login_view.dart';
import '../../features/auth/presentation/views/register_view.dart';
import '../../features/ai_chat/presentation/views/ai_chat_view.dart';

import '../../features/settings/presentation/views/settings_view.dart';

import '../../features/splash/presentation/views/splash_view.dart';
import 'go_router_refresh_stream.dart';

class AppRoutes {
  static const String splash = '/';
  static const String home = '/schedule';
  static const String login = '/login';
  static const String register = '/register';
  static const String aiChat = '/ai-chat';
  static const String settings = '/settings';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    refreshListenable: GoRouterRefreshStream(sl<AuthCubit>().stream),
    redirect: (context, state) {
      final authState = sl<AuthCubit>().state;
      final isAuthenticated =
          authState is Authenticated ||
          Supabase.instance.client.auth.currentUser != null;

      final isLoggingIn =
          state.matchedLocation == login || state.matchedLocation == register;
      final isSplash = state.matchedLocation == splash;

      if (isSplash) return null; // Let splash handle navigation

      if (!isAuthenticated && !isLoggingIn) {
        return login;
      }
      if (isAuthenticated && isLoggingIn) {
        return home;
      }
      return null;
    },
    routes: [
      GoRoute(path: splash, builder: (context, state) => const SplashView()),
      GoRoute(path: home, builder: (context, state) => const Root()),
      GoRoute(path: login, builder: (context, state) => const LoginView()),
      GoRoute(
        path: register,
        builder: (context, state) => const RegisterView(),
      ),
      GoRoute(path: aiChat, builder: (context, state) => const AiChatView()),
      GoRoute(
        path: settings,
        builder: (context, state) => const SettingsView(),
      ),
    ],
  );
}
