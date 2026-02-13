import '../entities/execution_set.dart';
import '../entities/workout_execution.dart';

/// Contract for workout execution data operations.
abstract interface class WorkoutExecutionRepository {
  Future<List<WorkoutExecution>> getAll();
  Future<List<WorkoutExecution>> getByWorkout(int workoutId);
  Future<WorkoutExecution?> getById(int id);
  Future<int> start(int workoutId);
  Future<void> finish(int executionId, {String? notes});
  Future<void> delete(int id);
  Future<List<ExecutionSet>> getSets(int executionId);
  Future<int> logSet(ExecutionSet set);
  Future<void> updateSet(ExecutionSet set);
}
