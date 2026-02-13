import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/execution_set.dart' as domain;
import '../../domain/entities/workout_execution.dart' as domain;
import '../../domain/repositories/workout_execution_repository.dart';
import '../datasources/daos/workout_execution_dao.dart';

class WorkoutExecutionRepositoryImpl implements WorkoutExecutionRepository {
  final WorkoutExecutionDao _dao;

  WorkoutExecutionRepositoryImpl(this._dao);

  @override
  Future<List<domain.WorkoutExecution>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map(_executionToDomain).toList();
  }

  @override
  Future<List<domain.WorkoutExecution>> getByWorkout(int workoutId) async {
    final rows = await _dao.getByWorkout(workoutId);
    return rows.map(_executionToDomain).toList();
  }

  @override
  Future<domain.WorkoutExecution?> getById(int id) async {
    final row = await _dao.getById(id);
    return row != null ? _executionToDomain(row) : null;
  }

  @override
  Future<int> start(int workoutId) => _dao.create(
        WorkoutExecutionsCompanion.insert(workoutId: workoutId),
      );

  @override
  Future<void> finish(int executionId, {String? notes}) =>
      _dao.finish(executionId, notes: notes);

  @override
  Future<void> delete(int id) => _dao.deleteById(id);

  @override
  Future<List<domain.ExecutionSet>> getSets(int executionId) async {
    final rows = await _dao.getSets(executionId);
    return rows.map(_setToDomain).toList();
  }

  @override
  Future<int> logSet(domain.ExecutionSet set) => _dao.insertSet(
        ExecutionSetsCompanion.insert(
          executionId: set.executionId,
          exerciseId: set.exerciseId,
          setNumber: set.setNumber,
          reps: set.reps,
          weight: Value(set.weight),
          isCompleted: Value(set.isCompleted),
        ),
      );

  @override
  Future<void> updateSet(domain.ExecutionSet set) => _dao.updateSet(
        set.id,
        ExecutionSetsCompanion(
          reps: Value(set.reps),
          weight: Value(set.weight),
          isCompleted: Value(set.isCompleted),
        ),
      );

  domain.WorkoutExecution _executionToDomain(dynamic row) =>
      domain.WorkoutExecution(
        id: row.id as int,
        workoutId: row.workoutId as int,
        startedAt: row.startedAt as DateTime,
        finishedAt: row.finishedAt as DateTime?,
        notes: row.notes as String?,
      );

  domain.ExecutionSet _setToDomain(dynamic row) => domain.ExecutionSet(
        id: row.id as int,
        executionId: row.executionId as int,
        exerciseId: row.exerciseId as int,
        setNumber: row.setNumber as int,
        reps: row.reps as int,
        weight: row.weight as double?,
        isCompleted: row.isCompleted as bool,
      );
}
