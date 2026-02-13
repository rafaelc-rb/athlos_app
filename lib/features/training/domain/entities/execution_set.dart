/// A single set performed during a workout execution.
class ExecutionSet {
  final int id;
  final int executionId;
  final int exerciseId;
  final int setNumber;
  final int reps;

  /// Weight used in kg. Null for bodyweight exercises.
  final double? weight;

  final bool isCompleted;

  const ExecutionSet({
    required this.id,
    required this.executionId,
    required this.exerciseId,
    required this.setNumber,
    required this.reps,
    this.weight,
    this.isCompleted = false,
  });
}
