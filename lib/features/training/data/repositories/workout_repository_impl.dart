import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/workout.dart' as domain;
import '../../domain/entities/workout_exercise.dart' as domain;
import '../../domain/repositories/workout_repository.dart';
import '../datasources/daos/workout_dao.dart';

class WorkoutRepositoryImpl implements WorkoutRepository {
  final WorkoutDao _dao;

  WorkoutRepositoryImpl(this._dao);

  @override
  Future<List<domain.Workout>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<domain.Workout?> getById(int id) async {
    final row = await _dao.getById(id);
    return row != null ? _toDomain(row) : null;
  }

  @override
  Future<int> create(
    domain.Workout workout,
    List<domain.WorkoutExercise> exercises,
  ) async {
    final id = await _dao.create(
      WorkoutsCompanion.insert(
        name: workout.name,
        description: Value(workout.description),
      ),
    );
    await _dao.setExercises(
      id,
      exercises
          .map((e) => WorkoutExercisesCompanion.insert(
                workoutId: id,
                exerciseId: e.exerciseId,
                order: e.order,
                sets: e.sets,
                reps: e.reps,
                restSeconds: Value(e.restSeconds),
              ))
          .toList(),
    );
    return id;
  }

  @override
  Future<void> update(
    domain.Workout workout,
    List<domain.WorkoutExercise> exercises,
  ) async {
    await _dao.updateById(
      workout.id,
      WorkoutsCompanion(
        name: Value(workout.name),
        description: Value(workout.description),
      ),
    );
    await _dao.setExercises(
      workout.id,
      exercises
          .map((e) => WorkoutExercisesCompanion.insert(
                workoutId: workout.id,
                exerciseId: e.exerciseId,
                order: e.order,
                sets: e.sets,
                reps: e.reps,
                restSeconds: Value(e.restSeconds),
              ))
          .toList(),
    );
  }

  @override
  Future<void> delete(int id) => _dao.deleteById(id);

  @override
  Future<List<domain.WorkoutExercise>> getExercises(int workoutId) async {
    final rows = await _dao.getExercises(workoutId);
    return rows
        .map((row) => domain.WorkoutExercise(
              workoutId: row.workoutId,
              exerciseId: row.exerciseId,
              order: row.order,
              sets: row.sets,
              reps: row.reps,
              restSeconds: row.restSeconds,
            ))
        .toList();
  }

  domain.Workout _toDomain(dynamic row) => domain.Workout(
        id: row.id as int,
        name: row.name as String,
        description: row.description as String?,
        createdAt: row.createdAt as DateTime,
      );
}
