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
  final bool isWarmup;

  /// Rate of Perceived Exertion (1–10). Null when not recorded.
  final int? rpe;

  /// Per-set user notes (e.g. "shoulder pain", "try wider grip").
  final String? notes;

  final int? leftReps;
  final double? leftWeight;
  final int? rightReps;
  final double? rightWeight;

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
    this.isWarmup = false,
    this.rpe,
    this.notes,
    this.leftReps,
    this.leftWeight,
    this.rightReps,
    this.rightWeight,
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
    bool? isWarmup,
    int? Function()? rpe,
    String? Function()? notes,
    int? Function()? leftReps,
    double? Function()? leftWeight,
    int? Function()? rightReps,
    double? Function()? rightWeight,
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
        isWarmup: isWarmup ?? this.isWarmup,
        rpe: rpe != null ? rpe() : this.rpe,
        notes: notes != null ? notes() : this.notes,
        leftReps: leftReps != null ? leftReps() : this.leftReps,
        leftWeight: leftWeight != null ? leftWeight() : this.leftWeight,
        rightReps: rightReps != null ? rightReps() : this.rightReps,
        rightWeight: rightWeight != null ? rightWeight() : this.rightWeight,
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
          isWarmup == other.isWarmup &&
          rpe == other.rpe &&
          leftReps == other.leftReps &&
          leftWeight == other.leftWeight &&
          rightReps == other.rightReps &&
          rightWeight == other.rightWeight;

  @override
  int get hashCode => Object.hash(id, setNumber, plannedReps, plannedWeight,
      reps, weight, duration, distance, isCompleted, isWarmup, rpe,
      leftReps, leftWeight, rightReps, rightWeight);
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

  /// Whether this session is running under deload adjustments.
  final bool isDeload;

  /// Fallback rest seconds from the active program's defaultRestSeconds.
  final int defaultRestSeconds;

  const ActiveExecutionState({
    required this.executionId,
    required this.workoutId,
    required this.exerciseSets,
    required this.exercises,
    this.isFinishing = false,
    this.isDeload = false,
    this.defaultRestSeconds = 0,
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
        defaultRestSeconds: defaultRestSeconds,
        isDeload: isDeload,
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
