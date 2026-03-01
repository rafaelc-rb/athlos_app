import 'package:drift/drift.dart';

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
          stepType: s.type == CycleStepType.rest ? 'rest' : 'workout',
          workoutId: Value(s.workoutId),
        );
      }).toList();
      await _dao.replaceAll(companions);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseException('Failed to save cycle steps: $e'));
    }
  }

  TrainingCycleStep _rowToDomain(CycleStep row) => TrainingCycleStep(
        id: row.id,
        orderIndex: row.orderIndex,
        type:
            row.stepType == 'rest' ? CycleStepType.rest : CycleStepType.workout,
        workoutId: row.workoutId,
      );
}
