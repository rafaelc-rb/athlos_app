import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/hub/presentation/screens/hub_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/training/presentation/screens/training_shell.dart';
import 'route_paths.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: RoutePaths.hub,
    routes: [
      // Hub (Olympus) — main entry point
      GoRoute(
        path: RoutePaths.hub,
        builder: (context, state) => const HubScreen(),
      ),

      // Profile
      GoRoute(
        path: RoutePaths.profile,
        builder: (context, state) => const ProfileScreen(),
      ),

      // Training module — shell with bottom navigation
      trainingShellRoute(),
    ],
  );
}
