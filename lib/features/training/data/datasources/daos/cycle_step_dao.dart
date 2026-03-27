import 'package:drift/drift.dart';

import '../../../../../core/database/app_database.dart';
import '../tables/cycle_steps_table.dart';

part 'cycle_step_dao.g.dart';

@DriftAccessor(tables: [CycleSteps])
class CycleStepDao extends DatabaseAccessor<AppDatabase> with _$CycleStepDaoMixin {
  CycleStepDao(super.db);

  /// Returns steps for the given [programId].
  /// Pass `null` to get free-cycle steps (no program).
  Future<List<CycleStep>> getAllOrdered({int? programId}) {
    final query = select(cycleSteps)
      ..orderBy([(s) => OrderingTerm.asc(s.orderIndex)]);
    if (programId != null) {
      query.where((s) => s.programId.equals(programId));
    } else {
      query.where((s) => s.programId.isNull());
    }
    return query.get();
  }

  /// Replaces all steps for the given [programId] (null = free cycle).
  Future<void> replaceAll(
    List<CycleStepsCompanion> entries, {
    int? programId,
  }) async {
    final deleteQuery = delete(cycleSteps);
    if (programId != null) {
      deleteQuery.where((s) => s.programId.equals(programId));
    } else {
      deleteQuery.where((s) => s.programId.isNull());
    }
    await deleteQuery.go();
    if (entries.isNotEmpty) {
      await batch((batch) => batch.insertAll(cycleSteps, entries));
    }
  }

  Future<int> insertStep(CycleStepsCompanion entry) =>
      into(cycleSteps).insert(entry);
}
