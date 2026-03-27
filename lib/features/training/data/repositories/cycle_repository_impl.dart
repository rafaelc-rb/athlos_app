import '../../../../core/database/app_database.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/cycle_step.dart';
import '../../domain/repositories/cycle_repository.dart';
import '../datasources/daos/cycle_step_dao.dart';

class CycleRepositoryImpl implements CycleRepository {
  CycleRepositoryImpl(this._dao);

  final CycleStepDao _dao;

  @override
  Future<Result<List<TrainingCycleStep>>> getSteps() async {
    try {
      final rows = await _dao.getAllOrdered();
      return Success(rows.map(_rowToDomain).toList());
    } on Exception catch (e) {
      return Failure(DatabaseException('Failed to load cycle steps: $e'));
    }
  }

  @override
  Future<Result<void>> setSteps(List<TrainingCycleStep> steps) async {
    try {
      final companions = steps.asMap().entries.map((e) {
        final s = e.value;
        return CycleStepsCompanion.insert(
          orderIndex: e.key,
          workoutId: s.workoutId,
        );
      }).toList();
      await _dao.replaceAll(companions);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseException('Failed to save cycle steps: $e'));
    }
  }

  @override
  Future<Result<void>> removeWorkoutFromCycle(int workoutId) async {
    try {
      final steps = await _dao.getAllOrdered();
      final filtered =
          steps.where((row) => row.workoutId != workoutId).toList();
      if (filtered.length == steps.length) return const Success(null);
      final companions = filtered.asMap().entries.map((e) {
        return CycleStepsCompanion.insert(
          orderIndex: e.key,
          workoutId: e.value.workoutId,
        );
      }).toList();
      await _dao.replaceAll(companions);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(
          DatabaseException('Failed to remove workout from cycle: $e'));
    }
  }

  @override
  Future<Result<void>> appendWorkoutToCycle(int workoutId) async {
    try {
      final steps = await _dao.getAllOrdered();
      final companions = steps.asMap().entries.map((e) {
        return CycleStepsCompanion.insert(
          orderIndex: e.key,
          workoutId: e.value.workoutId,
        );
      }).toList();
      companions.add(CycleStepsCompanion.insert(
        orderIndex: steps.length,
        workoutId: workoutId,
      ));
      await _dao.replaceAll(companions);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(
          DatabaseException('Failed to append workout to cycle: $e'));
    }
  }

  @override
  Future<Result<void>> syncWithActiveWorkoutIds(List<int> activeIds) async {
    if (activeIds.isEmpty) return const Success(null);
    try {
      final steps = await _dao.getAllOrdered();
      final inCycle = {for (final row in steps) row.workoutId};
      final toAdd = activeIds.where((id) => !inCycle.contains(id)).toList();
      if (toAdd.isEmpty) return const Success(null);
      final companions = steps.asMap().entries.map((e) {
        return CycleStepsCompanion.insert(
          orderIndex: e.key,
          workoutId: e.value.workoutId,
        );
      }).toList();
      for (var i = 0; i < toAdd.length; i++) {
        companions.add(CycleStepsCompanion.insert(
          orderIndex: steps.length + i,
          workoutId: toAdd[i],
        ));
      }
      await _dao.replaceAll(companions);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(
          DatabaseException('Failed to sync cycle with active workouts: $e'));
    }
  }

  TrainingCycleStep _rowToDomain(CycleStep row) => TrainingCycleStep(
        id: row.id,
        orderIndex: row.orderIndex,
        workoutId: row.workoutId,
      );
}
