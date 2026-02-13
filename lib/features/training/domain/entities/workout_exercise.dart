/// Configuration of an exercise within a workout (sets, reps, rest).
class WorkoutExercise {
  final int workoutId;
  final int exerciseId;
  final int order;
  final int sets;
  final int reps;

  /// Rest time between sets in seconds.
  final int restSeconds;

  const WorkoutExercise({
    required this.workoutId,
    required this.exerciseId,
    required this.order,
    required this.sets,
    required this.reps,
    required this.restSeconds,
  });
}
