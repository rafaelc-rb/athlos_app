import '../../../../core/errors/result.dart';
import '../entities/cycle_step.dart';

/// Contract for training cycle (ordered steps: workout or rest).
abstract interface class CycleRepository {
  Future<Result<List<TrainingCycleStep>>> getSteps();
  Future<Result<void>> setSteps(List<TrainingCycleStep> steps);

  /// Removes any cycle step that references this workout (e.g. when workout is archived).
  Future<Result<void>> removeWorkoutFromCycle(int workoutId);

  /// Appends a workout step at the end of the cycle (e.g. when creating or unarchiving a workout).
  Future<Result<void>> appendWorkoutToCycle(int workoutId);

  /// Appends a rest step at the end of the cycle.
  Future<Result<void>> appendRestToCycle();

  /// Ensures every [activeIds] workout is in the cycle; appends any missing at the end.
  Future<Result<void>> syncWithActiveWorkoutIds(List<int> activeIds);
}
