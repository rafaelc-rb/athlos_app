import 'package:drift/drift.dart';

import 'programs_table.dart';
import 'workouts_table.dart';

/// A single step in the training cycle (ordered workout reference).
/// Steps with null [programId] belong to the free cycle (no program).
class CycleSteps extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get programId =>
      integer().nullable().references(Programs, #id)();
  IntColumn get orderIndex => integer()();
  IntColumn get workoutId => integer().references(Workouts, #id)();
}
