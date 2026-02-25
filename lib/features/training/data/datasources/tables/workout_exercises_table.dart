import 'package:drift/drift.dart';

import 'exercises_table.dart';
import 'workouts_table.dart';

/// Junction table: Workout ↔ Exercise (many-to-many with config).
class WorkoutExercises extends Table {
  IntColumn get workoutId => integer().references(Workouts, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get order => integer()();
  IntColumn get sets => integer()();

  /// Target reps per set. Null for cardio exercises.
  IntColumn get reps => integer().nullable()();

  /// Rest time between sets in seconds.
  IntColumn get rest => integer().withDefault(const Constant(60))();

  /// Planned duration per set in seconds. Used for cardio exercises.
  IntColumn get duration => integer().nullable()();

  /// Superset group ID within the workout. Exercises sharing the same
  /// non-null groupId are executed back-to-back before rest.
  IntColumn get groupId => integer().nullable()();

  @override
  Set<Column> get primaryKey => {workoutId, exerciseId};
}
