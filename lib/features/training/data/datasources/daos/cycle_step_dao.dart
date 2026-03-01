import 'package:drift/drift.dart';

import '../../../../../core/database/app_database.dart';
import '../tables/cycle_steps_table.dart';

part 'cycle_step_dao.g.dart';

@DriftAccessor(tables: [CycleSteps])
class CycleStepDao extends DatabaseAccessor<AppDatabase> with _$CycleStepDaoMixin {
  CycleStepDao(super.db);

  Future<List<CycleStep>> getAllOrdered() =>
      (select(cycleSteps)..orderBy([(s) => OrderingTerm.asc(s.orderIndex)]))
          .get();

  Future<void> replaceAll(List<CycleStepsCompanion> entries) async {
    await delete(cycleSteps).go();
    if (entries.isNotEmpty) {
      await batch((batch) => batch.insertAll(cycleSteps, entries));
    }
  }

  Future<int> insertStep(CycleStepsCompanion entry) =>
      into(cycleSteps).insert(entry);
}
