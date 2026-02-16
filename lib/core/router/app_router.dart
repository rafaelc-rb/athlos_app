import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/hub/presentation/screens/hub_screen.dart';
import '../../features/profile/presentation/providers/profile_notifier.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/profile_setup_screen.dart';
import '../../features/training/presentation/screens/training_shell.dart';
import 'route_paths.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  // Watch the hasProfile provider to trigger router refresh on change
  final hasProfileAsync = ref.watch(hasProfileProvider);

  return GoRouter(
    initialLocation: RoutePaths.hub,
    redirect: (context, state) {
      final isOnSetup = state.matchedLocation == RoutePaths.profileSetup;

      // While loading, don't redirect
      if (hasProfileAsync.isLoading) return null;

      final hasProfile = hasProfileAsync.value ?? false;

      // No profile and not on setup -> go to setup
      if (!hasProfile && !isOnSetup) return RoutePaths.profileSetup;

      // Has profile but on setup -> go to hub
      if (hasProfile && isOnSetup) return RoutePaths.hub;

      return null;
    },
    routes: [
      // Hub (Olympus) — main entry point
      GoRoute(
        path: RoutePaths.hub,
        builder: (context, state) => const HubScreen(),
      ),

      // Profile setup (first launch)
      GoRoute(
        path: RoutePaths.profileSetup,
        builder: (context, state) => const ProfileSetupScreen(),
      ),

      // Profile view/edit
      GoRoute(
        path: RoutePaths.profile,
        builder: (context, state) => const ProfileScreen(),
      ),

      // Training module — shell with bottom navigation
      trainingShellRoute(),
    ],
  );
}
