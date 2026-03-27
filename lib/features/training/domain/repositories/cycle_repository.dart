import '../../../../core/errors/result.dart';
import '../entities/cycle_step.dart';

/// Contract for the training cycle (ordered queue of workouts).
///
/// All methods accept an optional [programId]. Pass `null` to operate on the
/// free cycle (no program); pass a program ID to operate on that program's cycle.
abstract interface class CycleRepository {
  Future<Result<List<TrainingCycleStep>>> getSteps({int? programId});
  Future<Result<void>> setSteps(List<TrainingCycleStep> steps,
      {int? programId});

  /// Removes any cycle step that references this workout (e.g. when archived).
  Future<Result<void>> removeWorkoutFromCycle(int workoutId,
      {int? programId});

  /// Appends a workout step at the end of the cycle.
  Future<Result<void>> appendWorkoutToCycle(int workoutId, {int? programId});

  /// Ensures every [activeIds] workout is in the cycle; appends any missing at the end.
  Future<Result<void>> syncWithActiveWorkoutIds(List<int> activeIds,
      {int? programId});
}
