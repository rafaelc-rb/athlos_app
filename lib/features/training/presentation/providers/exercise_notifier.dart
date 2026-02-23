import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/result.dart';
import '../../data/repositories/training_providers.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/enums/muscle_group.dart';

part 'exercise_notifier.g.dart';

/// Loads all exercises from the repository.
@riverpod
class ExerciseList extends _$ExerciseList {
  @override
  Future<List<Exercise>> build() async {
    final repo = ref.watch(exerciseRepositoryProvider);
    final result = await repo.getAll();
    return result.getOrThrow();
  }
}

/// Loads exercises filtered by a specific muscle group.
@riverpod
Future<List<Exercise>> exercisesByMuscleGroup(
  Ref ref,
  MuscleGroup group,
) async {
  final repo = ref.watch(exerciseRepositoryProvider);
  final result = await repo.getByMuscleGroup(group);
  return result.getOrThrow();
}

/// Loads variations for a specific exercise.
@riverpod
Future<List<Exercise>> exerciseVariations(Ref ref, int exerciseId) async {
  final repo = ref.watch(exerciseRepositoryProvider);
  final result = await repo.getVariations(exerciseId);
  return result.getOrThrow();
}

/// Loads equipment IDs linked to a specific exercise.
@riverpod
Future<List<int>> exerciseEquipmentIds(Ref ref, int exerciseId) async {
  final repo = ref.watch(exerciseRepositoryProvider);
  final result = await repo.getEquipmentIds(exerciseId);
  return result.getOrThrow();
}
