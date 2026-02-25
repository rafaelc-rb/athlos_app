import 'package:drift/drift.dart';

import 'exercises_table.dart';
import 'workout_executions_table.dart';

/// Individual set performed during a workout execution.
class ExecutionSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get executionId => integer().references(WorkoutExecutions, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get setNumber => integer()();

  /// Snapshot of the template reps at the time of execution. Null for cardio.
  IntColumn get plannedReps => integer().nullable()();

  /// Target weight (from last session or user input). Null if not set.
  RealColumn get plannedWeight => real().nullable()();

  /// Actual reps performed (primary segment for drop sets). Null for cardio.
  IntColumn get reps => integer().nullable()();

  /// Actual weight used in kg (primary segment for drop sets).
  RealColumn get weight => real().nullable()();

  /// Actual duration performed in seconds. Used for cardio exercises.
  IntColumn get duration => integer().nullable()();

  /// Actual distance covered in meters. Used for cardio exercises.
  RealColumn get distance => real().nullable()();

  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();

  /// Per-set user notes (e.g. "felt easy", "pain in shoulder").
  TextColumn get notes => text().nullable()();
}
