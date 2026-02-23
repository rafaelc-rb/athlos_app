import '../../../../core/errors/result.dart';
import '../entities/exercise.dart';
import '../enums/muscle_group.dart';

/// Contract for exercise data operations.
abstract interface class ExerciseRepository {
  Future<Result<List<Exercise>>> getAll();
  Future<Result<Exercise?>> getById(int id);
  Future<Result<List<Exercise>>> getByMuscleGroup(MuscleGroup group);
  Future<Result<List<Exercise>>> getVariations(int exerciseId);
  Future<Result<List<int>>> getEquipmentIds(int exerciseId);
  Future<Result<int>> create(Exercise exercise,
      {List<int> equipmentIds = const []});
  Future<Result<void>> update(Exercise exercise, {List<int>? equipmentIds});
  Future<Result<void>> delete(int id);
  Future<Result<void>> addVariation(int exerciseId, int variationId);
  Future<Result<void>> removeVariation(int exerciseId, int variationId);
}
