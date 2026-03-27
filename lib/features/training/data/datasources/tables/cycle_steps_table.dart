import 'package:drift/drift.dart';

import 'workouts_table.dart';

/// A single step in the training cycle (ordered workout reference).
class CycleSteps extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orderIndex => integer()();
  IntColumn get workoutId => integer().references(Workouts, #id)();
}
