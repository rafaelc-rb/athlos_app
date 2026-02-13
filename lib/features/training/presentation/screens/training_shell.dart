import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../l10n/app_localizations.dart';
import 'training_home_screen.dart';
import 'training_workouts_screen.dart';
import 'training_exercises_screen.dart';
import 'training_history_screen.dart';

/// Training module shell with bottom navigation bar.
///
/// Uses `StatefulShellRoute` from go_router to keep each tab's
/// navigation state independent. Each tab is a `StatefulShellBranch`.
///
/// This is the recommended pattern from go_router for bottom navigation:
/// - Each branch has its own Navigator
/// - Navigation state is preserved when switching tabs

/// Factory function that returns the training `ShellRoute`.
/// Called from `app_router.dart` to keep the router file clean.
ShellRoute trainingShellRoute() {
  return ShellRoute(
    builder: (context, state, child) {
      return _TrainingShell(child: child);
    },
    routes: [
      GoRoute(
        path: RoutePaths.training,
        redirect: (context, state) {
          // /training redirects to /training/home
          if (state.fullPath == RoutePaths.training) {
            return RoutePaths.trainingHome;
          }
          return null;
        },
      ),
      GoRoute(
        path: RoutePaths.trainingHome,
        builder: (context, state) => const TrainingHomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.trainingWorkouts,
        builder: (context, state) => const TrainingWorkoutsScreen(),
      ),
      GoRoute(
        path: RoutePaths.trainingExercises,
        builder: (context, state) => const TrainingExercisesScreen(),
      ),
      GoRoute(
        path: RoutePaths.trainingHistory,
        builder: (context, state) => const TrainingHistoryScreen(),
      ),
    ],
  );
}

class _TrainingShell extends StatelessWidget {
  final Widget child;

  const _TrainingShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentPath =
        GoRouterState.of(context).fullPath ?? RoutePaths.trainingHome;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RoutePaths.hub),
        ),
        title: Text(l10n.trainingModule),
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indexFromPath(currentPath),
        onDestinationSelected: (index) => _onTabTap(context, index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.tabHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.view_list_outlined),
            selectedIcon: const Icon(Icons.view_list),
            label: l10n.tabWorkouts,
          ),
          NavigationDestination(
            icon: const Icon(Icons.sports_gymnastics_outlined),
            selectedIcon: const Icon(Icons.sports_gymnastics),
            label: l10n.tabExercises,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: l10n.tabHistory,
          ),
        ],
      ),
    );
  }

  int _indexFromPath(String path) {
    if (path.startsWith(RoutePaths.trainingWorkouts)) return 1;
    if (path.startsWith(RoutePaths.trainingExercises)) return 2;
    if (path.startsWith(RoutePaths.trainingHistory)) return 3;
    return 0;
  }

  void _onTabTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(RoutePaths.trainingHome);
      case 1:
        context.go(RoutePaths.trainingWorkouts);
      case 2:
        context.go(RoutePaths.trainingExercises);
      case 3:
        context.go(RoutePaths.trainingHistory);
    }
  }
}
