import 'package:drift/drift.dart';

import 'exercises_table.dart';
import 'workout_executions_table.dart';

/// Individual set performed during a workout execution.
class ExecutionSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get executionId => integer().references(WorkoutExecutions, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get setNumber => integer()();
  IntColumn get reps => integer()();

  /// Weight in kg. Null for bodyweight exercises.
  RealColumn get weight => real().nullable()();

  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();
}
