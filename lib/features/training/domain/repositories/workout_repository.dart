import '../../../../core/errors/result.dart';
import '../entities/workout.dart';
import '../entities/workout_exercise.dart';

/// Contract for workout data operations.
abstract interface class WorkoutRepository {
  Future<Result<List<Workout>>> getAll();
  Future<Result<Workout?>> getById(int id);
  Future<Result<int>> create(Workout workout, List<WorkoutExercise> exercises);
  Future<Result<void>> update(Workout workout, List<WorkoutExercise> exercises);
  Future<Result<void>> delete(int id);
  Future<Result<List<WorkoutExercise>>> getExercises(int workoutId);
}
