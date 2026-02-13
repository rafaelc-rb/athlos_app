import '../entities/exercise.dart';
import '../enums/muscle_group.dart';

/// Contract for exercise data operations.
abstract interface class ExerciseRepository {
  Future<List<Exercise>> getAll();
  Future<Exercise?> getById(int id);
  Future<List<Exercise>> getByMuscleGroup(MuscleGroup group);
  Future<List<Exercise>> getVariations(int exerciseId);
  Future<List<int>> getEquipmentIds(int exerciseId);
  Future<int> create(Exercise exercise, {List<int> equipmentIds = const []});
  Future<void> update(Exercise exercise, {List<int>? equipmentIds});
  Future<void> delete(int id);
  Future<void> addVariation(int exerciseId, int variationId);
  Future<void> removeVariation(int exerciseId, int variationId);
}
