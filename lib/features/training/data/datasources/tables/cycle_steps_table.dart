import 'package:drift/drift.dart';

import 'workouts_table.dart';

/// A single step in the training cycle (workout or rest).
class CycleSteps extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orderIndex => integer()();
  /// 'workout' or 'rest'
  TextColumn get stepType => text()();
  /// Non-null when stepType is 'workout'
  IntColumn get workoutId => integer().nullable().references(Workouts, #id)();
}
