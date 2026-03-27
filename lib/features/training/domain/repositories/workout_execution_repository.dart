import '../../../../core/errors/result.dart';
import '../entities/execution_comparison.dart';
import '../entities/execution_set.dart';
import '../entities/execution_set_segment.dart';
import '../entities/workout_execution.dart';

/// Contract for workout execution data operations.
abstract interface class WorkoutExecutionRepository {
  Future<Result<List<WorkoutExecution>>> getAll();
  Future<Result<List<WorkoutExecution>>> getByWorkout(int workoutId);
  Future<Result<WorkoutExecution?>> getById(int id);
  Future<Result<WorkoutExecution?>> getLastFinished();

  /// Last two finished executions for [workoutId] with total volume (weight×reps).
  /// Returns null if there are fewer than two finished executions.
  Future<Result<ExecutionComparison?>> getLastTwoFinishedWithVolume(
      int workoutId);
  Future<Result<int>> start(int workoutId, {int? programId});
  Future<Result<void>> finish(int executionId, {String? notes});
  Future<Result<void>> delete(int id);
  Future<Result<List<ExecutionSet>>> getSets(int executionId);
  Future<Result<int>> logSet(ExecutionSet set);
  Future<Result<void>> updateSet(ExecutionSet set);
  Future<Result<Map<int, double>>> getLastWeightsForExercises(
      List<int> exerciseIds);

  /// Completed non-warmup sets from the most recent finished execution
  /// that included [exerciseId].
  Future<Result<List<ExecutionSet>>> getLastCompletedSetsForExercise(
      int exerciseId);

  // --- Segments (drop sets) ---
  Future<Result<List<ExecutionSetSegment>>> getSegments(int executionSetId);
  Future<Result<List<ExecutionSetSegment>>> getSegmentsForExecution(
      int executionId);
  Future<Result<void>> saveSegments(
      int executionSetId, List<ExecutionSetSegment> segments);
}
