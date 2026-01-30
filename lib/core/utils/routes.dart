import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/roots.dart';
import '../../features/auth/presentation/views/login_view.dart';
import '../../features/auth/presentation/views/register_view.dart';
import '../../features/ai_chat/presentation/views/ai_chat_view.dart';

class AppRoutes {
  static const String home = '/schedule';
  static const String login = '/login';
  static const String register = '/register';
  static const String aiChat = '/ai-chat';

  static final GoRouter router = GoRouter(
    initialLocation: home,
    redirect: (context, state) {
      final isAuthenticated = Supabase.instance.client.auth.currentUser != null;
      final isLoggingIn =
          state.matchedLocation == login || state.matchedLocation == register;

      if (!isAuthenticated && !isLoggingIn) {
        return login;
      }
      if (isAuthenticated && isLoggingIn) {
        return home;
      }
      return null;
    },
    routes: [
      GoRoute(path: home, builder: (context, state) => const Root()),
      GoRoute(path: login, builder: (context, state) => const LoginView()),
      GoRoute(
        path: register,
        builder: (context, state) => const RegisterView(),
      ),
      GoRoute(path: aiChat, builder: (context, state) => const AiChatView()),
    ],
  );
}
