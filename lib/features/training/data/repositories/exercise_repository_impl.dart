import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/exercise.dart' as domain;
import '../../domain/enums/muscle_group.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../datasources/daos/exercise_dao.dart';

class ExerciseRepositoryImpl implements ExerciseRepository {
  final ExerciseDao _dao;

  ExerciseRepositoryImpl(this._dao);

  @override
  Future<List<domain.Exercise>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<domain.Exercise?> getById(int id) async {
    final row = await _dao.getById(id);
    return row != null ? _toDomain(row) : null;
  }

  @override
  Future<List<domain.Exercise>> getByMuscleGroup(MuscleGroup group) async {
    final rows = await _dao.getByMuscleGroup(group);
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<domain.Exercise>> getVariations(int exerciseId) async {
    final rows = await _dao.getVariations(exerciseId);
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<int>> getEquipmentIds(int exerciseId) =>
      _dao.getEquipmentIds(exerciseId);

  @override
  Future<int> create(
    domain.Exercise exercise, {
    List<int> equipmentIds = const [],
  }) async {
    final id = await _dao.create(
      ExercisesCompanion.insert(
        name: exercise.name,
        muscleGroup: exercise.muscleGroup,
        targetMuscles: Value(exercise.targetMuscles),
        muscleRegion: Value(exercise.muscleRegion),
        description: Value(exercise.description),
        isCustom: Value(exercise.isCustom),
      ),
    );
    if (equipmentIds.isNotEmpty) {
      await _dao.setEquipments(id, equipmentIds);
    }
    return id;
  }

  @override
  Future<void> update(
    domain.Exercise exercise, {
    List<int>? equipmentIds,
  }) async {
    await _dao.updateById(
      exercise.id,
      ExercisesCompanion(
        name: Value(exercise.name),
        muscleGroup: Value(exercise.muscleGroup),
        targetMuscles: Value(exercise.targetMuscles),
        muscleRegion: Value(exercise.muscleRegion),
        description: Value(exercise.description),
        isCustom: Value(exercise.isCustom),
      ),
    );
    if (equipmentIds != null) {
      await _dao.setEquipments(exercise.id, equipmentIds);
    }
  }

  @override
  Future<void> delete(int id) => _dao.deleteById(id);

  @override
  Future<void> addVariation(int exerciseId, int variationId) =>
      _dao.addVariation(exerciseId, variationId);

  @override
  Future<void> removeVariation(int exerciseId, int variationId) =>
      _dao.removeVariation(exerciseId, variationId);

  domain.Exercise _toDomain(dynamic row) => domain.Exercise(
        id: row.id as int,
        name: row.name as String,
        muscleGroup: row.muscleGroup as MuscleGroup,
        targetMuscles: row.targetMuscles as String?,
        muscleRegion: row.muscleRegion as String?,
        description: row.description as String?,
        isCustom: row.isCustom as bool,
      );
}
