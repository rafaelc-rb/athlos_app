import '../../domain/entities/workout_exercise.dart';

/// In-memory representation of a drop set segment during active execution.
///
/// Unlike [ExecutionSetSegment] (domain entity persisted to DB),
/// this is a transient UI model used while the execution is in progress.
class SegmentEntry {
  final int reps;
  final double? weight;

  const SegmentEntry({required this.reps, this.weight});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SegmentEntry &&
          runtimeType == other.runtimeType &&
          reps == other.reps &&
          weight == other.weight;

  @override
  int get hashCode => Object.hash(reps, weight);
}

/// In-memory representation of a set during active execution.
///
/// Unlike [ExecutionSet] (domain entity persisted to DB),
/// this tracks both planned and actual values in a mutable form
/// before persistence.
class SetEntry {
  final int? id;
  final int setNumber;
  final int? plannedReps;
  final double? plannedWeight;
  final int? reps;
  final double? weight;

  /// Duration in seconds for cardio exercises.
  final int? duration;

  /// Distance in meters for cardio exercises.
  final double? distance;

  final bool isCompleted;

  /// Rate of Perceived Exertion (1–10). Null when not recorded.
  final int? rpe;

  final List<SegmentEntry> segments;

  const SetEntry({
    this.id,
    required this.setNumber,
    this.plannedReps,
    this.plannedWeight,
    this.reps,
    this.weight,
    this.duration,
    this.distance,
    this.isCompleted = false,
    this.rpe,
    this.segments = const [],
  });

  bool get isDropSet => segments.length > 1;

  SetEntry copyWith({
    int? id,
    int? setNumber,
    int? Function()? plannedReps,
    double? Function()? plannedWeight,
    int? Function()? reps,
    double? Function()? weight,
    int? Function()? duration,
    double? Function()? distance,
    bool? isCompleted,
    int? Function()? rpe,
    List<SegmentEntry>? segments,
  }) =>
      SetEntry(
        id: id ?? this.id,
        setNumber: setNumber ?? this.setNumber,
        plannedReps:
            plannedReps != null ? plannedReps() : this.plannedReps,
        plannedWeight:
            plannedWeight != null ? plannedWeight() : this.plannedWeight,
        reps: reps != null ? reps() : this.reps,
        weight: weight != null ? weight() : this.weight,
        duration: duration != null ? duration() : this.duration,
        distance: distance != null ? distance() : this.distance,
        isCompleted: isCompleted ?? this.isCompleted,
        rpe: rpe != null ? rpe() : this.rpe,
        segments: segments ?? this.segments,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          setNumber == other.setNumber &&
          plannedReps == other.plannedReps &&
          plannedWeight == other.plannedWeight &&
          reps == other.reps &&
          weight == other.weight &&
          duration == other.duration &&
          distance == other.distance &&
          isCompleted == other.isCompleted &&
          rpe == other.rpe;

  @override
  int get hashCode => Object.hash(id, setNumber, plannedReps, plannedWeight,
      reps, weight, duration, distance, isCompleted, rpe);
}

/// Holds the full state of an active workout execution in progress.
class ActiveExecutionState {
  final int executionId;
  final int workoutId;

  /// exerciseId -> list of sets for that exercise.
  final Map<int, List<SetEntry>> exerciseSets;

  /// Ordered exercise configs to access rest per exercise.
  final List<WorkoutExercise> exercises;
  final bool isFinishing;

  const ActiveExecutionState({
    required this.executionId,
    required this.workoutId,
    required this.exerciseSets,
    required this.exercises,
    this.isFinishing = false,
  });

  int get completedSetCount => exerciseSets.values
      .expand((sets) => sets)
      .where((s) => s.isCompleted)
      .length;

  bool get hasCompletedSets => completedSetCount > 0;

  ActiveExecutionState copyWith({
    Map<int, List<SetEntry>>? exerciseSets,
    bool? isFinishing,
  }) =>
      ActiveExecutionState(
        executionId: executionId,
        workoutId: workoutId,
        exerciseSets: exerciseSets ?? this.exerciseSets,
        exercises: exercises,
        isFinishing: isFinishing ?? this.isFinishing,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveExecutionState &&
          runtimeType == other.runtimeType &&
          executionId == other.executionId &&
          workoutId == other.workoutId &&
          isFinishing == other.isFinishing;

  @override
  int get hashCode => Object.hash(executionId, workoutId, isFinishing);
}
