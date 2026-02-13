/// Record of a completed (or in-progress) workout execution.
class WorkoutExecution {
  final int id;
  final int workoutId;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final String? notes;

  const WorkoutExecution({
    required this.id,
    required this.workoutId,
    required this.startedAt,
    this.finishedAt,
    this.notes,
  });

  bool get isFinished => finishedAt != null;

  Duration? get duration => finishedAt?.difference(startedAt);
}
