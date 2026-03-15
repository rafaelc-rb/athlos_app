/// Configuration of an exercise within a workout (sets, reps, rest).
class WorkoutExercise {
  final int workoutId;
  final int exerciseId;
  final int order;
  final int sets;

  /// Target reps per set. Null for cardio exercises.
  final int? reps;

  /// Rest time between sets in seconds.
  final int rest;

  /// Planned duration per set in seconds. Used for cardio exercises.
  final int? duration;

  /// Superset group ID. Exercises sharing the same non-null groupId
  /// are executed back-to-back before rest.
  final int? groupId;

  /// Whether this exercise is performed unilaterally (one side at a time).
  final bool isUnilateral;

  /// Free-text execution notes (postural cues, technique reminders, etc.).
  final String? notes;

  const WorkoutExercise({
    required this.workoutId,
    required this.exerciseId,
    required this.order,
    required this.sets,
    this.reps,
    required this.rest,
    this.duration,
    this.groupId,
    this.isUnilateral = false,
    this.notes,
  });
}
