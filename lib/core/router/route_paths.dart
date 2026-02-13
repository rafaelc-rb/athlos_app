/// Centralized route path constants.
///
/// All route paths live here so that navigation is consistent and
/// refactoring a path requires changing only one place.
abstract final class RoutePaths {
  // Hub
  static const hub = '/';

  // Profile
  static const profile = '/profile';

  // Training module
  static const training = '/training';
  static const trainingHome = '/training/home';
  static const trainingWorkouts = '/training/workouts';
  static const trainingExercises = '/training/exercises';
  static const trainingHistory = '/training/history';

  // Diet module (future)
  static const diet = '/diet';
}
