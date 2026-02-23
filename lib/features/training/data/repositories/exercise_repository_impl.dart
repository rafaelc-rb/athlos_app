import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/exercise.dart' as domain;
import '../../domain/enums/muscle_group.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../datasources/daos/exercise_dao.dart';

class ExerciseRepositoryImpl implements ExerciseRepository {
  final ExerciseDao _dao;

  ExerciseRepositoryImpl(this._dao);

  @override
  Future<Result<List<domain.Exercise>>> getAll() async {
    try {
      final rows = await _dao.getAll();
      return Success(rows.map(_toDomain).toList());
    } on Exception catch (e) {
      return Failure(DatabaseException('Failed to load exercises: $e'));
    }
  }

  @override
  Future<Result<domain.Exercise?>> getById(int id) async {
    try {
      final row = await _dao.getById(id);
      return Success(row != null ? _toDomain(row) : null);
    } on Exception catch (e) {
      return Failure(DatabaseException('Failed to load exercise $id: $e'));
    }
  }

  @override
  Future<Result<List<domain.Exercise>>> getByMuscleGroup(
      MuscleGroup group) async {
    try {
      final rows = await _dao.getByMuscleGroup(group);
      return Success(rows.map(_toDomain).toList());
    } on Exception catch (e) {
      return Failure(
          DatabaseException('Failed to load exercises by muscle group: $e'));
    }
  }

  @override
  Future<Result<List<domain.Exercise>>> getVariations(int exerciseId) async {
    try {
      final rows = await _dao.getVariations(exerciseId);
      return Success(rows.map(_toDomain).toList());
    } on Exception catch (e) {
      return Failure(DatabaseException('Failed to load variations: $e'));
    }
  }

  @override
  Future<Result<List<int>>> getEquipmentIds(int exerciseId) async {
    try {
      final ids = await _dao.getEquipmentIds(exerciseId);
      return Success(ids);
    } on Exception catch (e) {
      return Failure(DatabaseException('Failed to load equipment ids: $e'));
    }
  }

  @override
  Future<Result<int>> create(
    domain.Exercise exercise, {
    List<int> equipmentIds = const [],
  }) async {
    try {
      final id = await _dao.create(
        ExercisesCompanion.insert(
          name: exercise.name,
          muscleGroup: exercise.muscleGroup,
          targetMuscles: Value(exercise.targetMuscles),
          muscleRegion: Value(exercise.muscleRegion),
          description: Value(exercise.description),
          isVerified: Value(exercise.isVerified),
        ),
      );
      if (equipmentIds.isNotEmpty) {
        await _dao.setEquipments(id, equipmentIds);
      }
      return Success(id);
    } on Exception catch (e) {
      return Failure(DatabaseException('Failed to create exercise: $e'));
    }
  }

  @override
  Future<Result<void>> update(
    domain.Exercise exercise, {
    List<int>? equipmentIds,
  }) async {
    try {
      await _dao.updateById(
        exercise.id,
        ExercisesCompanion(
          name: Value(exercise.name),
          muscleGroup: Value(exercise.muscleGroup),
          targetMuscles: Value(exercise.targetMuscles),
          muscleRegion: Value(exercise.muscleRegion),
          description: Value(exercise.description),
          isVerified: Value(exercise.isVerified),
        ),
      );
      if (equipmentIds != null) {
        await _dao.setEquipments(exercise.id, equipmentIds);
      }
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseException('Failed to update exercise: $e'));
    }
  }

  @override
  Future<Result<void>> delete(int id) async {
    try {
      await _dao.deleteById(id);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseException('Failed to delete exercise $id: $e'));
    }
  }

  @override
  Future<Result<void>> addVariation(int exerciseId, int variationId) async {
    try {
      await _dao.addVariation(exerciseId, variationId);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseException('Failed to add variation: $e'));
    }
  }

  @override
  Future<Result<void>> removeVariation(int exerciseId, int variationId) async {
    try {
      await _dao.removeVariation(exerciseId, variationId);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseException('Failed to remove variation: $e'));
    }
  }

  domain.Exercise _toDomain(dynamic row) => domain.Exercise(
        id: row.id as int,
        name: row.name as String,
        muscleGroup: row.muscleGroup as MuscleGroup,
        targetMuscles: row.targetMuscles as String?,
        muscleRegion: row.muscleRegion as String?,
        description: row.description as String?,
        isVerified: row.isVerified as bool,
      );
}
