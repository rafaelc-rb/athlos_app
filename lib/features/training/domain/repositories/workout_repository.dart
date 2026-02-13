import '../entities/workout.dart';
import '../entities/workout_exercise.dart';

/// Contract for workout data operations.
abstract interface class WorkoutRepository {
  Future<List<Workout>> getAll();
  Future<Workout?> getById(int id);
  Future<int> create(Workout workout, List<WorkoutExercise> exercises);
  Future<void> update(Workout workout, List<WorkoutExercise> exercises);
  Future<void> delete(int id);
  Future<List<WorkoutExercise>> getExercises(int workoutId);
}
