import 'package:go_router/go_router.dart';
import '../../features/roots.dart';

class AppRoutes {
  static const String home = '/';

  static final GoRouter router = GoRouter(
    initialLocation: home,
    routes: [GoRoute(path: home, builder: (context, state) => const Root())],
  );
}
